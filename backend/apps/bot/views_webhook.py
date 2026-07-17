"""
Webhook view for Telegram Bot — receives updates from Telegram API.
"""
import json
import os
import asyncio
import logging

from django.http import HttpResponse, HttpResponseNotAllowed
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

logger = logging.getLogger(__name__)

# Lazy-init singleton for bot + dispatcher + event loop
_bot = None
_dp = None
_initialized = False
_loop = None


def _ensure_bot():
    """Initialize bot and dispatcher once."""
    global _bot, _dp, _initialized
    if _initialized:
        return _bot is not None

    _initialized = True
    token = _get_token()
    if not token:
        logger.error("BOT_TOKEN not configured — webhook cannot start.")
        return False

    try:
        from aiogram import Bot, Dispatcher
        from aiogram.client.default import DefaultBotProperties
        from aiogram.enums import ParseMode
        from aiogram.filters import CommandStart, Command

        _bot = Bot(token=token, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
        _dp = Dispatcher()

        # ---------- Register handlers (with sync_to_async for DB access) ----------
        from asgiref.sync import sync_to_async

        @_dp.message(CommandStart())
        async def start_handler(message):
            user = message.from_user
            await message.answer(
                f"<b>Добро пожаловать, {user.first_name}!</b>\n\n"
                f"Это бот My Exchange. Администраторы назначаются через панель управления.\n\n"
                f"<b>Команды:</b>\n"
                f"/help — список команд"
            )

        @_dp.message(Command('help'))
        async def help_handler(message):
            text = (
                "<b>🤖 My Exchange Бот</b>\n\n"
                "<b>Доступные команды:</b>\n"
                "/start — зарегистрироваться как администратор\n"
                "/help — показать эту справку\n"
                "/status — статус бота и статистика\n"
                "/requests — последние заявки на регистрацию\n\n"
                "<b>О боте:</b>\n"
                "Этот бот уведомляет администраторов о новых заявках\n"
                "на регистрацию с лендинг страницы My Exchange."
            )
            await message.answer(text)

        @_dp.message(Command('status'))
        async def status_handler(message):
            from apps.bot.models import BotAdmin
            from apps.requests.models import RegistrationRequest

            @sync_to_async
            def get_stats():
                admins_count = BotAdmin.objects.filter(is_active=True).count()
                pending_requests = RegistrationRequest.objects.filter(status='pending').count()
                total_requests = RegistrationRequest.objects.count()
                return admins_count, pending_requests, total_requests

            admins_count, pending_requests, total_requests = await get_stats()

            text = (
                f"<b>📊 Статус бота</b>\n\n"
                f"✅ Бот активен (вебхук)\n"
                f"👤 Администраторов: {admins_count}\n"
                f"📝 Всего заявок: {total_requests}\n"
                f"⏳ Ожидают: {pending_requests}"
            )
            await message.answer(text)

        @_dp.message(Command('requests'))
        async def requests_handler(message):
            from apps.requests.models import RegistrationRequest

            @sync_to_async
            def get_pending_requests():
                return list(RegistrationRequest.objects.filter(status='pending')[:5])

            requests = await get_pending_requests()

            if not requests:
                await message.answer("📭 Нет новых заявок на рассмотрении.")
                return
            text = "<b>📋 Последние заявки:</b>\n\n"
            for i, req in enumerate(requests, 1):
                text += (
                    f"{i}. <b>{req.name}</b>\n"
                    f"   📞 {req.phone}\n"
                )
                if req.email:
                    text += f"   📧 {req.email}\n"
                if req.organization_name:
                    text += f"   🏢 {req.organization_name}\n"
                text += f"   🕐 {req.created_at.strftime('%d.%m.%Y %H:%M')}\n\n"
            await message.answer(text)

        @_dp.message()
        async def unknown_handler(message):
            await message.answer("❌ Неизвестная команда. Используйте /help для списка команд.")

        return True
    except Exception as e:
        logger.exception(f"Failed to init webhook bot: {e}")
        return False


def _get_token():
    """Get bot token from BotConfig or environment."""
    try:
        from apps.bot.models import BotConfig
        config = BotConfig.objects.filter(key='BOT_TOKEN').first()
        if config and config.value:
            return config.value.strip()
    except Exception:
        pass
    return os.environ.get('BOT_TOKEN')


def _get_secret_token():
    """Get webhook secret token from BotConfig or environment."""
    try:
        from apps.bot.models import BotConfig
        config = BotConfig.objects.filter(key='BOT_WEBHOOK_SECRET').first()
        if config and config.value:
            return config.value.strip()
    except Exception:
        pass
    return os.environ.get('BOT_WEBHOOK_SECRET')


@csrf_exempt
@require_POST
def telegram_webhook(request):
    """
    Handle incoming Telegram update via webhook.

    Telegram sends POST with JSON body. We parse it and feed
    it to the aiogram Dispatcher for processing.
    """
    # Validate secret token if configured (prevents fake updates)
    secret = _get_secret_token()
    if secret:
        received = request.headers.get('X-Telegram-Bot-Api-Secret-Token')
        if received != secret:
            logger.warning("Webhook called with invalid secret token — rejecting")
            return HttpResponse(status=403)

    # Lazy‑init the bot (after Django is fully loaded)
    if not _ensure_bot():
        logger.warning("Bot not configured — webhook returning 200 anyway.")
        return HttpResponse(status=200)

    try:
        update_data = json.loads(request.body)
    except json.JSONDecodeError:
        logger.error("Invalid JSON in webhook request")
        return HttpResponse(status=400)

    # Feed update to dispatcher (async → sync bridge)
    # Use a persistent event loop instead of asyncio.run() to avoid
    # "Event loop is closed" RuntimeError on subsequent webhook calls.
    async def _process():
        from aiogram.types import Update
        update = Update.model_validate(update_data)
        await _dp.feed_update(_bot, update)

    global _loop
    try:
        if _loop is None or _loop.is_closed():
            _loop = asyncio.new_event_loop()
            asyncio.set_event_loop(_loop)
        _loop.run_until_complete(_process())
    except Exception as e:
        logger.exception(f"Error processing update: {e}")
        # Reset loop on error to avoid reusing a broken event loop
        if _loop and not _loop.is_closed():
            _loop.close()
        _loop = None

    # Telegram expects 200 OK
    return HttpResponse(status=200)

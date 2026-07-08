"""
Telegram bot notifier - standalone functions to notify bot admins about new requests.

Uses a cached Bot singleton (created once) with per-call synchronous event loop.
The Bot instance is reused to avoid re-authorization overhead.
"""
import os
import asyncio
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Cached Bot instance (reused across calls)
_bot = None


def _ensure_bot():
    """Get or create the persistent Bot singleton."""
    global _bot
    if _bot is not None:
        return _bot

    try:
        from aiogram import Bot
        from aiogram.client.default import DefaultBotProperties
        from aiogram.enums import ParseMode

        token = _get_bot_token()
        if not token:
            logger.error("BOT_TOKEN is not configured.")
            return None

        _bot = Bot(token=token, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
        logger.info("Bot notifier singleton initialized")
        return _bot
    except Exception as e:
        logger.error(f"Failed to initialize bot notifier: {e}")
        return None


def _get_bot_token() -> Optional[str]:
    """Get bot token from BotConfig or environment variable."""
    try:
        from apps.bot.models import BotConfig
        config = BotConfig.objects.filter(key='BOT_TOKEN').first()
        if config and config.value:
            return config.value.strip()
    except Exception:
        pass
    return os.environ.get('BOT_TOKEN')


def _get_admin_ids():
    """Get list of active admin telegram IDs."""
    try:
        from apps.bot.models import BotAdmin
        admins = BotAdmin.objects.filter(is_active=True)
        return [admin.telegram_id for admin in admins]
    except Exception:
        return []


def notify_new_request(instance) -> bool:
    """
    Notify all active bot admins about a new registration request.
    Bot instance is cached (created once). A new event loop is created per call
    for safe synchronous usage in Django views.
    """
    bot = _ensure_bot()
    if bot is None:
        logger.warning("Bot not configured, skipping notification")
        return False

    admin_ids = _get_admin_ids()
    if not admin_ids:
        logger.info("No active bot admins to notify")
        return False

    # Build notification message
    message = f"<b>Новая заявка на регистрацию!</b>\n\n"
    message += f"<b>Имя:</b> {instance.name}\n"
    message += f"<b>Телефон:</b> {instance.phone}\n"
    if instance.email:
        message += f"<b>Email:</b> {instance.email}\n"
    if instance.organization_name:
        message += f"<b>Организация:</b> {instance.organization_name}\n"
    if instance.comment:
        message += f"<b>Комментарий:</b> {instance.comment}\n"
    message += f"\n#заявка{instance.id}"

    async def _send():
        success = True
        for admin_id in admin_ids:
            try:
                await bot.send_message(chat_id=admin_id, text=message)
                logger.info(f"Notification sent to admin {admin_id}")
            except Exception as e:
                logger.error(f"Failed to send notification to {admin_id}: {e}")
                success = False
        return success

    try:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        result = loop.run_until_complete(_send())
        loop.close()
        return result
    except Exception as e:
        logger.error(f"Error sending Telegram notification: {e}")
        return False

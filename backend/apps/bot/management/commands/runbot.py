"""
Management command to start the Telegram bot using aiogram.

Usage: python manage.py runbot
"""
import os
import asyncio
import logging

from django.core.management.base import BaseCommand
from django.conf import settings

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Запускает Telegram бота для уведомлений о новых заявках'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Запуск Telegram бота...'))

        try:
            from aiogram import Bot, Dispatcher, types
            from aiogram.client.default import DefaultBotProperties
            from aiogram.enums import ParseMode
            from aiogram.filters import CommandStart, Command
        except ImportError:
            self.stdout.write(self.style.ERROR(
                'aiogram не установлен. Установите: pip install aiogram==3.17.0'
            ))
            return

        # Get token
        token = self._get_token()
        if not token:
            self.stdout.write(self.style.ERROR(
                'Токен бота не найден. Добавьте BOT_TOKEN в BotConfig или в переменную окружения.'
            ))
            return

        async def main():
            bot = Bot(token=token, default=DefaultBotProperties(parse_mode=ParseMode.HTML))
            dp = Dispatcher()

            # ---------- Register handlers (with sync_to_async for DB access) ----------
            from asgiref.sync import sync_to_async

            @dp.message(CommandStart())
            async def start_handler(message: types.Message):
                """Handle /start command - show welcome message without registration."""
                user = message.from_user
                await message.answer(
                    f"<b>Добро пожаловать, {user.first_name}!</b>\n\n"
                    f"Это бот My Exchange. Администраторы назначаются через панель управления.\n\n"
                    f"<b>Команды:</b>\n"
                    f"/help — список команд"
                )

            @dp.message(Command('help'))
            async def help_handler(message: types.Message):
                """Handle /help command."""
                help_text = (
                    "<b>🤖 My Exchange Бот</b>\n\n"
                    "<b>Доступные команды:</b>\n"
                    "/start - Зарегистрироваться как администратор\n"
                    "/help - Показать эту справку\n"
                    "/status - Статус бота и статистика\n"
                    "/requests - Последние заявки на регистрацию\n\n"
                    "<b>О боте:</b>\n"
                    "Этот бот уведомляет администраторов о новых заявках\n"
                    "на регистрацию с лендинг страницы My Exchange."
                )
                await message.answer(help_text)

            @dp.message(Command('status'))
            async def status_handler(message: types.Message):
                """Handle /status command."""
                from apps.bot.models import BotAdmin
                from apps.requests.models import RegistrationRequest

                @sync_to_async
                def get_stats():
                    admins_count = BotAdmin.objects.filter(is_active=True).count()
                    pending_requests = RegistrationRequest.objects.filter(status='pending').count()
                    total_requests = RegistrationRequest.objects.count()
                    return admins_count, pending_requests, total_requests

                admins_count, pending_requests, total_requests = await get_stats()

                status_text = (
                    f"<b>📊 Статус бота</b>\n\n"
                    f"✅ Бот активен\n"
                    f"👤 Администраторов: {admins_count}\n"
                    f"📝 Всего заявок: {total_requests}\n"
                    f"⏳ Ожидают: {pending_requests}"
                )
                await message.answer(status_text)

            @dp.message(Command('requests'))
            async def requests_handler(message: types.Message):
                """Handle /requests command - show recent requests."""
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

            @dp.message()
            async def unknown_handler(message: types.Message):
                """Handle unknown messages."""
                await message.answer(
                    "❌ Неизвестная команда. Используйте /help для списка команд."
                )

            self.stdout.write(self.style.SUCCESS('Бот запущен и готов к работе!'))
            # Start polling
            await dp.start_polling(bot)

        try:
            asyncio.run(main())
        except KeyboardInterrupt:
            self.stdout.write(self.style.WARNING('\nБот остановлен.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Ошибка бота: {e}'))
            logger.exception(e)

    def _get_token(self):
        """Get bot token from BotConfig or environment."""
        try:
            from apps.bot.models import BotConfig
            config = BotConfig.objects.filter(key='BOT_TOKEN').first()
            if config and config.value:
                return config.value.strip()
        except Exception:
            pass
        return os.environ.get('BOT_TOKEN')

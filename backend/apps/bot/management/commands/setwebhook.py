"""
Management command to set or delete the Telegram bot webhook.

Usage:
    python manage.py setwebhook                      # Set webhook (uses BOT_WEBHOOK_URL from env/BotConfig)
    python manage.py setwebhook --url https://...     # Set custom webhook URL
    python manage.py setwebhook --delete               # Delete current webhook
"""
import os
import asyncio
import logging

from django.core.management.base import BaseCommand, CommandError

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Установить или удалить вебхук Telegram бота'

    def add_arguments(self, parser):
        parser.add_argument('--url', type=str, help='Публичный HTTPS URL для вебхука')
        parser.add_argument('--delete', action='store_true', help='Удалить текущий вебхук')
        parser.add_argument('--secret-token', type=str, help='Secret token для верификации запросов')

    def handle(self, *args, **options):
        try:
            from aiogram import Bot
            from aiogram.client.default import DefaultBotProperties
            from aiogram.enums import ParseMode
        except ImportError:
            raise CommandError('aiogram не установлен. pip install aiogram==3.17.0')

        token = self._get_token()
        if not token:
            raise CommandError(
                'Токен бота не найден. Укажите BOT_TOKEN в BotConfig (ключ BOT_TOKEN) '
                'или в переменной окружения BOT_TOKEN.'
            )

        async def _run():
            bot = Bot(token=token, default=DefaultBotProperties(parse_mode=ParseMode.HTML))

            if options['delete']:
                self.stdout.write('Удаление вебхука...')
                result = await bot.delete_webhook(drop_pending_updates=True)
                if result:
                    self.stdout.write(self.style.SUCCESS('✅ Вебхук удалён.'))
                else:
                    self.stdout.write(self.style.WARNING('⚠️ Не удалось удалить вебхук.'))
                return

            # Determine webhook URL
            webhook_url = options.get('url') or self._get_webhook_url()
            if not webhook_url:
                raise CommandError(
                    'Укажите URL вебхука через --url https://example.com/webhook/telegram/ '
                    'или установите BOT_WEBHOOK_URL в BotConfig (ключ BOT_WEBHOOK_URL) / переменную окружения.'
                )

            secret_token = options.get('secret_token') or self._get_secret_token() or None

            self.stdout.write(f'Установка вебхука: {webhook_url}')
            if secret_token:
                self.stdout.write('🔐 Используется secret token для верификации запросов.')

            allowed_updates = ['message']

            result = await bot.set_webhook(
                url=webhook_url,
                allowed_updates=allowed_updates,
                secret_token=secret_token,
                drop_pending_updates=True,
            )

            if result:
                # Get webhook info summary
                info = await bot.get_webhook_info()
                self.stdout.write(self.style.SUCCESS(f'✅ Вебхук установлен!'))
                self.stdout.write(f'   URL:         {info.url}')
                self.stdout.write(f'   Ожидает:     {info.pending_update_count}')
                self.stdout.write(f'   Последняя ошибка: {info.last_error_message or "—"}')
            else:
                self.stdout.write(self.style.ERROR('❌ Не удалось установить вебхук.'))

            await bot.session.close()

        asyncio.run(_run())

    def _get_token(self):
        try:
            from apps.bot.models import BotConfig
            config = BotConfig.objects.filter(key='BOT_TOKEN').first()
            if config and config.value:
                return config.value.strip()
        except Exception:
            pass
        return os.environ.get('BOT_TOKEN')

    def _get_webhook_url(self):
        try:
            from apps.bot.models import BotConfig
            config = BotConfig.objects.filter(key='BOT_WEBHOOK_URL').first()
            if config and config.value:
                return config.value.strip()
        except Exception:
            pass
        return os.environ.get('BOT_WEBHOOK_URL')

    def _get_secret_token(self):
        try:
            from apps.bot.models import BotConfig
            config = BotConfig.objects.filter(key='BOT_WEBHOOK_SECRET').first()
            if config and config.value:
                return config.value.strip()
        except Exception:
            pass
        return os.environ.get('BOT_WEBHOOK_SECRET')

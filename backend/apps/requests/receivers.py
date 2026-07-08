"""
Signal receivers for Registration Requests app.
Sends new request notifications to the Telegram bot.
"""
import logging
from django.conf import settings
from .signals import request_created

logger = logging.getLogger(__name__)


def notify_telegram_bot(instance):
    """
    Notify Telegram bot admins about a new registration request.
    """
    try:
        from bot_service.notifier import notify_new_request
        notify_new_request(instance)
    except Exception as e:
        logger.error(f"Failed to notify Telegram bot: {e}")


def request_created_handler(sender, instance, **kwargs):
    """
    Handle new registration request creation.
    """
    notify_telegram_bot(instance)


request_created.connect(request_created_handler)

"""
URLs for Telegram bot webhook.
"""
from django.urls import path
from .views_webhook import telegram_webhook

urlpatterns = [
    path('', telegram_webhook, name='telegram-webhook'),
]

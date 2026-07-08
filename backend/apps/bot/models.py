"""
Models for Telegram Bot app.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _


class BotAdmin(models.Model):
    """
    Model for Telegram bot administrators who receive notifications.
    """
    telegram_id = models.BigIntegerField(
        unique=True,
        verbose_name=_('Telegram ID')
    )
    username = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Username')
    )
    first_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Имя')
    )
    last_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Фамилия')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активен')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата добавления')
    )

    class Meta:
        verbose_name = _('Администратор бота')
        verbose_name_plural = _('Администраторы бота')
        ordering = ['-created_at']

    def __str__(self):
        name = self.username or f"{self.first_name} {self.last_name}".strip() or str(self.telegram_id)
        return f"{name} ({self.telegram_id})"


class BotConfig(models.Model):
    """
    Model for storing Telegram bot configuration.
    """
    key = models.CharField(
        max_length=255,
        unique=True,
        verbose_name=_('Ключ')
    )
    value = models.TextField(
        verbose_name=_('Значение')
    )
    description = models.CharField(
        max_length=500,
        blank=True,
        verbose_name=_('Описание')
    )

    class Meta:
        verbose_name = _('Конфигурация бота')
        verbose_name_plural = _('Конфигурация бота')

    def __str__(self):
        return self.key

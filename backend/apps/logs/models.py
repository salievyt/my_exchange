"""
Logging models for audit trail.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.conf import settings


class ActionType(models.TextChoices):
    """Action types for logging."""
    LOGIN = 'login', _('Вход')
    LOGOUT = 'logout', _('Выход')
    CREATE = 'create', _('Создание')
    UPDATE = 'update', _('Изменение')
    DELETE = 'delete', _('Удаление')
    CANCEL = 'cancel', _('Отмена')
    PRINT = 'print', _('Печать')
    EXPORT = 'export', _('Экспорт')
    CHANGE_RATE = 'change_rate', _('Изменение курса')
    DEPOSIT = 'deposit', _('Внесение')
    WITHDRAWAL = 'withdrawal', _('Изъятие')


class AuditLog(models.Model):
    """Audit log for tracking all system actions."""
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='audit_logs',
        verbose_name=_('Пользователь')
    )
    action = models.CharField(
        max_length=50,
        choices=ActionType.choices,
        verbose_name=_('Действие')
    )
    model_name = models.CharField(
        max_length=100,
        blank=True,
        verbose_name=_('Модель')
    )
    object_id = models.PositiveIntegerField(
        null=True,
        blank=True,
        verbose_name=_('ID объекта')
    )
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        verbose_name=_('IP-адрес')
    )
    user_agent = models.TextField(
        blank=True,
        verbose_name=_('Устройство')
    )
    details = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_('Детали')
    )
    timestamp = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Время')
    )
    
    class Meta:
        verbose_name = _('Лог аудита')
        verbose_name_plural = _('Логи аудита')
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['-timestamp']),
            models.Index(fields=['user', '-timestamp']),
            models.Index(fields=['action', '-timestamp']),
            models.Index(fields=['model_name', '-timestamp']),
        ]
    
    def __str__(self):
        return f"{self.user.username if self.user else 'System'} - {self.action} - {self.timestamp}"

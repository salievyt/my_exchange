"""
Models for Notifications app.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _


class AppVersion(models.Model):
    """Track latest app version for update notifications."""

    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
    ]

    platform = models.CharField(
        max_length=20,
        choices=PLATFORM_CHOICES,
        verbose_name=_('Платформа'),
    )
    version = models.CharField(
        max_length=20,
        verbose_name=_('Версия'),
        help_text=_('Например: 1.1.0'),
    )
    build_number = models.IntegerField(
        default=1,
        verbose_name=_('Номер сборки'),
    )
    is_required = models.BooleanField(
        default=False,
        verbose_name=_('Обязательное обновление'),
    )
    update_url = models.URLField(
        blank=True,
        verbose_name=_('Ссылка на обновление'),
    )
    changelog = models.TextField(
        blank=True,
        verbose_name=_('Список изменений'),
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активно'),
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания'),
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления'),
    )

    class Meta:
        verbose_name = _('Версия приложения')
        verbose_name_plural = _('Версии приложений')
        ordering = ['-created_at']
        unique_together = [['platform', 'build_number']]

    def __str__(self):
        return f"{self.get_platform_display()} v{self.version}"

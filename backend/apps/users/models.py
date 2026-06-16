"""
User models for My Exchange project.
Implements role-based access control.
"""
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class Role(models.TextChoices):
    """User roles based on requirements."""
    CASHIER = 'cashier', _('Кассир')
    SENIOR_CASHIER = 'senior_cashier', _('Старший кассир')
    ADMIN = 'admin', _('Администратор')


class User(AbstractUser):
    """Custom user model with role-based access."""
    
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.CASHIER,
        verbose_name=_('Роль')
    )
    phone = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_('Телефон')
    )
    is_two_factor_enabled = models.BooleanField(
        default=False,
        verbose_name=_('Двухфакторная авторизация')
    )
    two_factor_secret = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_('Секрет 2FA')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания')
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления')
    )
    
    class Meta:
        verbose_name = _('Пользователь')
        verbose_name_plural = _('Пользователи')
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"
    
    @property
    def is_cashier(self):
        return self.role == Role.CASHIER
    
    @property
    def is_senior_cashier(self):
        return self.role in [Role.CASHIER, Role.SENIOR_CASHIER]
    
    @property
    def is_admin(self):
        return self.role == Role.ADMIN


class LoginHistory(models.Model):
    """Login history for audit trail."""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='login_history',
        verbose_name=_('Пользователь')
    )
    login_time = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Время входа')
    )
    logout_time = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Время выхода')
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
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активная сессия')
    )
    
    class Meta:
        verbose_name = _('История входа')
        verbose_name_plural = _('История входов')
        ordering = ['-login_time']
    
    def __str__(self):
        return f"{self.user.username} - {self.login_time}"

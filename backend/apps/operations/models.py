"""
Operation models for My Exchange project.
"""
from django.db import models
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from django.conf import settings
import uuid


class OperationType(models.TextChoices):
    """Operation types."""
    BUY = 'buy', _('Покупка валюты')
    SELL = 'sell', _('Продажа валюты')


class OperationStatus(models.TextChoices):
    """Operation status."""
    ACTIVE = 'active', _('Активна')
    CANCELLED = 'cancelled', _('Отменена')
    PARTIALLY_CANCELLED = 'partially_cancelled', _('Частично отменена')


class Operation(models.Model):
    """Main operation model for currency exchange."""
    
    operation_number = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name=_('Номер операции')
    )
    operation_type = models.CharField(
        max_length=20,
        choices=OperationType.choices,
        verbose_name=_('Тип операции')
    )
    status = models.CharField(
        max_length=20,
        choices=OperationStatus.choices,
        default=OperationStatus.ACTIVE,
        verbose_name=_('Статус')
    )
    
    # Client information (optional)
    client_name = models.CharField(
        max_length=200,
        blank=True,
        verbose_name=_('Имя клиента')
    )
    client_company = models.CharField(
        max_length=200,
        blank=True,
        verbose_name=_('Компания клиента')
    )
    
    # Currency details
    currency = models.ForeignKey(
        'currencies.Currency',
        on_delete=models.PROTECT,
        related_name='operations',
        verbose_name=_('Валюта')
    )
    rate = models.DecimalField(
        max_digits=12,
        decimal_places=4,
        verbose_name=_('Курс обмена')
    )
    
    # Amounts
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        verbose_name=_('Сумма валюты')
    )
    total_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        verbose_name=_('Общая сумма (KGS)')
    )
    
    # Cashier
    cashier = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='operations',
        verbose_name=_('Кассир')
    )
    
    # Additional info
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий')
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата и время создания')
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата и время обновления')
    )
    
    class Meta:
        verbose_name = _('Операция')
        verbose_name_plural = _('Операции')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['operation_number']),
            models.Index(fields=['cashier', '-created_at']),
            models.Index(fields=['status', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.operation_number} - {self.get_operation_type_display()}"
    
    def save(self, *args, **kwargs):
        if not self.operation_number:
            # Use timezone.now() as fallback since created_at is set after save via auto_now_add
            now = timezone.now()
            date_str = self.created_at.strftime('%Y%m%d') if self.created_at else now.strftime('%Y%m%d')
            unique_id = uuid.uuid4().hex[:6].upper()
            self.operation_number = f"OP-{date_str}-{unique_id}"
        super().save(*args, **kwargs)


class OperationEditHistory(models.Model):
    """History of operation edits for audit trail."""
    
    operation = models.ForeignKey(
        Operation,
        on_delete=models.CASCADE,
        related_name='edit_history',
        verbose_name=_('Операция')
    )
    edited_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        verbose_name=_('Редактировал')
    )
    edited_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата редактирования')
    )
    field_changed = models.CharField(
        max_length=100,
        verbose_name=_('Изменённое поле')
    )
    old_value = models.TextField(
        blank=True,
        verbose_name=_('Старое значение')
    )
    new_value = models.TextField(
        blank=True,
        verbose_name=_('Новое значение')
    )
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий к изменению')
    )
    
    class Meta:
        verbose_name = _('История редактирования операции')
        verbose_name_plural = _('История редактирования операций')
        ordering = ['-edited_at']


class OperationCancellation(models.Model):
    """Operation cancellation records."""
    
    operation = models.ForeignKey(
        Operation,
        on_delete=models.CASCADE,
        related_name='cancellations',
        verbose_name=_('Операция')
    )
    cancelled_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        verbose_name=_('Отменил')
    )
    cancelled_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата отмены')
    )
    cancellation_type = models.CharField(
        max_length=20,
        choices=[
            ('full', _('Полная отмена')),
            ('partial', _('Частичная отмена')),
        ],
        verbose_name=_('Тип отмены')
    )
    cancel_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name=_('Сумма отмены')
    )
    reason = models.TextField(
        verbose_name=_('Причина отмены')
    )
    
    class Meta:
        verbose_name = _('Отмена операции')
        verbose_name_plural = _('Отмены операций')
        ordering = ['-cancelled_at']

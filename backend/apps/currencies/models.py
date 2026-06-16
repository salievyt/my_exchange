"""
Currency models for My Exchange project.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.conf import settings


class Currency(models.Model):
    """Currency model."""
    
    code = models.CharField(
        max_length=3,
        unique=True,
        verbose_name=_('Код валюты')
    )
    name = models.CharField(
        max_length=100,
        verbose_name=_('Название')
    )
    symbol = models.CharField(
        max_length=10,
        blank=True,
        verbose_name=_('Символ')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активна')
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
        verbose_name = _('Валюта')
        verbose_name_plural = _('Валюты')
        ordering = ['code']
    
    def __str__(self):
        return f"{self.code} - {self.name}"


class ExchangeRate(models.Model):
    """Exchange rate model with history tracking."""
    
    OPERATION_TYPE_CHOICES = [
        ('buy', _('Покупка')),
        ('sell', _('Продажа')),
    ]
    
    currency = models.ForeignKey(
        Currency,
        on_delete=models.CASCADE,
        related_name='exchange_rates',
        verbose_name=_('Валюта')
    )
    base_currency = models.ForeignKey(
        Currency,
        on_delete=models.CASCADE,
        related_name='base_rates',
        limit_choices_to={'code': 'KGS'},
        verbose_name=_('Базовая валюта'),
        null=True,
        blank=True
    )
    rate = models.DecimalField(
        max_digits=12,
        decimal_places=4,
        verbose_name=_('Курс')
    )
    operation_type = models.CharField(
        max_length=10,
        choices=OPERATION_TYPE_CHOICES,
        verbose_name=_('Тип операции')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Действующий курс')
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_rates',
        verbose_name=_('Создал')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания')
    )
    valid_from = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Действует с')
    )
    valid_until = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Действует до')
    )
    
    class Meta:
        verbose_name = _('Курс обмена')
        verbose_name_plural = _('Курсы обмена')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['currency', 'operation_type', 'is_active']),
        ]
    
    def __str__(self):
        return f"{self.currency.code} ({self.get_operation_type_display()}) - {self.rate}"
    
    def save(self, *args, **kwargs):
        # Set base_currency to KGS if not provided
        if not self.base_currency_id:
            kgs_currency = Currency.objects.filter(code='KGS').first()
            if kgs_currency:
                self.base_currency = kgs_currency
        
        # Deactivate previous rates for same currency and operation type
        if self.is_active:
            ExchangeRate.objects.filter(
                currency=self.currency,
                operation_type=self.operation_type,
                is_active=True
            ).exclude(id=self.id).update(
                is_active=False,
                valid_until=self.created_at
            )
        super().save(*args, **kwargs)


class CurrencyRateHistory(models.Model):
    """History of exchange rate changes for audit."""
    
    currency = models.ForeignKey(
        Currency,
        on_delete=models.CASCADE,
        verbose_name=_('Валюта')
    )
    old_rate = models.DecimalField(
        max_digits=12,
        decimal_places=4,
        verbose_name=_('Старый курс')
    )
    new_rate = models.DecimalField(
        max_digits=12,
        decimal_places=4,
        verbose_name=_('Новый курс')
    )
    operation_type = models.CharField(
        max_length=10,
        choices=ExchangeRate.OPERATION_TYPE_CHOICES,
        verbose_name=_('Тип операции')
    )
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        verbose_name=_('Изменил')
    )
    changed_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата изменения')
    )
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий')
    )
    
    class Meta:
        verbose_name = _('История изменений курса')
        verbose_name_plural = _('История изменений курсов')
        ordering = ['-changed_at']

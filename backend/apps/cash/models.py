"""
Cash management models for My Exchange project.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.conf import settings


class CashTransactionType(models.TextChoices):
    """Cash transaction types."""
    DEPOSIT = 'deposit', _('Внесение наличности')
    WITHDRAWAL = 'withdrawal', _('Выдача наличности')
    INKASSATION = 'inkassation', _('Инкассация')


class CashBalance(models.Model):
    """Cash balance for each currency."""
    
    currency = models.OneToOneField(
        'currencies.Currency',
        on_delete=models.CASCADE,
        related_name='cash_balance',
        verbose_name=_('Валюта')
    )
    balance = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        verbose_name=_('Остаток')
    )
    reserved = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        verbose_name=_('Зарезервировано')
    )
    last_updated = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Последнее обновление')
    )
    
    class Meta:
        verbose_name = _('Кассовый остаток')
        verbose_name_plural = _('Кассовые остатки')
    
    def __str__(self):
        return f"{self.currency.code} - {self.balance}"
    
    @property
    def available_balance(self):
        """Get available balance (excluding reserved)."""
        return self.balance - self.reserved


class CashTransaction(models.Model):
    """Cash transaction history."""
    
    transaction_type = models.CharField(
        max_length=20,
        choices=CashTransactionType.choices,
        verbose_name=_('Тип операции')
    )
    currency = models.ForeignKey(
        'currencies.Currency',
        on_delete=models.PROTECT,
        related_name='cash_transactions',
        verbose_name=_('Валюта')
    )
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        verbose_name=_('Сумма')
    )
    balance_before = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        verbose_name=_('Остаток до')
    )
    balance_after = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        verbose_name=_('Остаток после')
    )
    cashier = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='cash_transactions',
        verbose_name=_('Кассир')
    )
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата и время')
    )
    
    class Meta:
        verbose_name = _('Кассовая операция')
        verbose_name_plural = _('Кассовые операции')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['cashier', '-created_at']),
            models.Index(fields=['currency', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_transaction_type_display()} - {self.amount} {self.currency.code}"


class CashRegister(models.Model):
    """Cash register session (shift)."""
    
    cashier = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='cash_registers',
        verbose_name=_('Кассир')
    )
    opened_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Открыта в')
    )
    closed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Закрыта в')
    )
    is_open = models.BooleanField(
        default=True,
        verbose_name=_('Открыта')
    )
    opening_balance = models.TextField(
        blank=True,
        help_text=_('JSON с начальными остатками по валютам')
    )
    closing_balance = models.TextField(
        blank=True,
        help_text=_('JSON с конечными остатками по валютам')
    )
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий')
    )
    
    class Meta:
        verbose_name = _('Кассовая смена')
        verbose_name_plural = _('Кассовые смены')
        ordering = ['-opened_at']
    
    def __str__(self):
        return f"Смена {self.cashier.username} - {self.opened_at.strftime('%Y-%m-%d %H:%M')}"

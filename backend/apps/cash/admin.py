"""
Admin configuration for Cash app.
"""
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import CashBalance, CashTransaction, CashRegister


@admin.register(CashBalance)
class CashBalanceAdmin(admin.ModelAdmin):
    """Admin for CashBalance model."""
    
    list_display = ['currency', 'balance', 'reserved', 'available_balance', 'last_updated']
    search_fields = ['currency__code', 'currency__name']
    readonly_fields = ['last_updated', 'available_balance']
    
    def available_balance(self, obj):
        return obj.available_balance
    available_balance.short_description = _('Доступно')


@admin.register(CashTransaction)
class CashTransactionAdmin(admin.ModelAdmin):
    """Admin for CashTransaction model."""
    
    list_display = [
        'transaction_type', 'currency', 'amount',
        'balance_before', 'balance_after', 'cashier', 'created_at'
    ]
    list_filter = ['transaction_type', 'currency', 'created_at']
    search_fields = ['cashier__username', 'comment']
    readonly_fields = ['balance_before', 'balance_after', 'created_at']
    date_hierarchy = 'created_at'


@admin.register(CashRegister)
class CashRegisterAdmin(admin.ModelAdmin):
    """Admin for CashRegister model."""
    
    list_display = ['cashier', 'opened_at', 'closed_at', 'is_open']
    list_filter = ['is_open', 'opened_at']
    search_fields = ['cashier__username']
    readonly_fields = ['opened_at', 'closed_at', 'is_open', 'opening_balance', 'closing_balance']
    
    def has_add_permission(self, request):
        return False

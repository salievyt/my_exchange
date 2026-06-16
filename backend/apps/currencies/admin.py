"""
Admin configuration for Currencies app.
"""
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Currency, ExchangeRate, CurrencyRateHistory


@admin.register(Currency)
class CurrencyAdmin(admin.ModelAdmin):
    """Admin for Currency model."""
    
    list_display = ['code', 'name', 'symbol', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['code', 'name']
    ordering = ['code']


@admin.register(ExchangeRate)
class ExchangeRateAdmin(admin.ModelAdmin):
    """Admin for ExchangeRate model."""
    
    list_display = ['currency', 'operation_type', 'rate', 'is_active', 'created_by', 'created_at']
    list_filter = ['operation_type', 'is_active', 'currency']
    search_fields = ['currency__code', 'created_by__username']
    readonly_fields = ['created_at', 'valid_from', 'valid_until']
    
    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(CurrencyRateHistory)
class CurrencyRateHistoryAdmin(admin.ModelAdmin):
    """Admin for rate history."""
    
    list_display = ['currency', 'old_rate', 'new_rate', 'operation_type', 'changed_by', 'changed_at']
    list_filter = ['operation_type', 'changed_at']
    search_fields = ['currency__code', 'changed_by__username']
    readonly_fields = ['currency', 'old_rate', 'new_rate', 'operation_type', 'changed_by', 'changed_at', 'comment']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False

"""
Admin configuration for Telegram Bot app.
"""
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import BotAdmin, BotConfig


@admin.register(BotAdmin)
class BotAdminAdmin(admin.ModelAdmin):
    """Admin for BotAdmin model."""

    list_display = ['telegram_id', 'username', 'first_name', 'last_name', 'is_active', 'created_at']
    list_filter = ['is_active']
    search_fields = ['telegram_id', 'username', 'first_name', 'last_name']
    readonly_fields = ['created_at']
    list_editable = ['is_active']

    fieldsets = (
        (_('Telegram'), {
            'fields': ('telegram_id', 'username', 'first_name', 'last_name')
        }),
        (_('Статус'), {
            'fields': ('is_active',)
        }),
        (_('Даты'), {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )


@admin.register(BotConfig)
class BotConfigAdmin(admin.ModelAdmin):
    """Admin for BotConfig model."""

    list_display = ['key', 'value', 'description']
    search_fields = ['key', 'description']

    fieldsets = (
        (_('Конфигурация'), {
            'fields': ('key', 'value', 'description')
        }),
    )

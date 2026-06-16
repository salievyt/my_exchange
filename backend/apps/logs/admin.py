"""
Admin configuration for Logs app.
"""
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Admin for AuditLog model."""
    
    list_display = ['user', 'action', 'model_name', 'object_id', 'ip_address', 'timestamp']
    list_filter = ['action', 'model_name', 'timestamp']
    search_fields = ['user__username', 'ip_address', 'details']
    readonly_fields = ['user', 'action', 'model_name', 'object_id', 'ip_address', 'user_agent', 'details', 'timestamp']
    date_hierarchy = 'timestamp'
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False

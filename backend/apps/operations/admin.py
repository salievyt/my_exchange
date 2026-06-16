"""
Admin configuration for Operations app.
"""
from django.contrib import admin
from django.utils.translation import gettext_lazy as _
from .models import Operation, OperationEditHistory, OperationCancellation


@admin.register(Operation)
class OperationAdmin(admin.ModelAdmin):
    """Admin for Operation model."""
    
    list_display = [
        'operation_number', 'operation_type', 'status', 'currency',
        'amount', 'rate', 'total_amount', 'cashier', 'created_at'
    ]
    list_filter = ['operation_type', 'status', 'currency', 'created_at']
    search_fields = ['operation_number', 'client_name', 'comment']
    readonly_fields = [
        'operation_number', 'total_amount', 'cashier',
        'created_at', 'updated_at'
    ]
    date_hierarchy = 'created_at'
    
    fieldsets = (
        (None, {
            'fields': ('operation_number', 'operation_type', 'status')
        }),
        (_('Client'), {
            'fields': ('client_name', 'client_company')
        }),
        (_('Currency details'), {
            'fields': ('currency', 'rate', 'amount', 'total_amount')
        }),
        (_('Cashier'), {
            'fields': ('cashier',)
        }),
        (_('Additional info'), {
            'fields': ('comment',)
        }),
        (_('Timestamps'), {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def has_change_permission(self, request, obj=None):
        # Only admin can change operations
        return request.user.role == 'admin'


@admin.register(OperationEditHistory)
class OperationEditHistoryAdmin(admin.ModelAdmin):
    """Admin for operation edit history."""
    
    list_display = ['operation', 'field_changed', 'edited_by', 'edited_at']
    list_filter = ['field_changed', 'edited_at']
    search_fields = ['operation__operation_number', 'edited_by__username']
    readonly_fields = ['operation', 'edited_by', 'edited_at', 'field_changed', 'old_value', 'new_value', 'comment']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False


@admin.register(OperationCancellation)
class OperationCancellationAdmin(admin.ModelAdmin):
    """Admin for operation cancellations."""
    
    list_display = ['operation', 'cancellation_type', 'cancel_amount', 'cancelled_by', 'cancelled_at']
    list_filter = ['cancellation_type', 'cancelled_at']
    search_fields = ['operation__operation_number', 'cancelled_by__username']
    readonly_fields = ['operation', 'cancelled_by', 'cancelled_at', 'cancellation_type', 'cancel_amount', 'reason']
    
    def has_add_permission(self, request):
        return False

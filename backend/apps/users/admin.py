"""
Admin configuration for Users app.
"""
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from .models import User, LoginHistory


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin for custom User model."""
    
    list_display = ['username', 'email', 'role', 'is_active', 'created_at']
    list_filter = ['role', 'is_active', 'is_staff']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    ordering = ['-created_at']
    
    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'email', 'phone')}),
        (_('Role'), {'fields': ('role',)}),
        (_('Two-factor auth'), {'fields': ('is_two_factor_enabled', 'two_factor_secret')}),
        (_('Permissions'), {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        (_('Important dates'), {'fields': ('last_login', 'created_at', 'updated_at')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'password1', 'password2', 'role'),
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(LoginHistory)
class LoginHistoryAdmin(admin.ModelAdmin):
    """Admin for login history."""
    
    list_display = ['user', 'login_time', 'logout_time', 'ip_address', 'is_active']
    list_filter = ['is_active', 'login_time']
    search_fields = ['user__username', 'ip_address']
    readonly_fields = ['user', 'login_time', 'logout_time', 'ip_address', 'user_agent']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False

"""
Admin configuration for Notifications app.
Full management interface for In-App Notification & Update Center.
"""
from django.contrib import admin
from django.utils.html import format_html
from .models import AppVersion, Notification, News


@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    """Admin for news items."""

    list_display = ['title', 'is_active', 'priority', 'published_at', 'expires_at']
    list_filter = ['is_active']
    search_fields = ['title', 'summary']
    ordering = ['-priority', '-published_at']
    list_editable = ['is_active', 'priority']

    fieldsets = [
        ('Content', {'fields': ['title', 'summary', 'body']}),
        ('Media & Link', {'fields': ['image_url', 'link_url', 'link_text']}),
        ('Settings', {'fields': ['is_active', 'priority', 'published_at', 'expires_at']}),
    ]


@admin.register(AppVersion)
class AppVersionAdmin(admin.ModelAdmin):
    """Admin for app version management."""
    
    list_display = ['platform', 'version', 'build_number', 'is_required', 'is_active', 'created_at']
    list_filter = ['platform', 'is_required', 'is_active']
    search_fields = ['version', 'changelog']
    ordering = ['-created_at']
    list_editable = ['is_required', 'is_active']
    
    fieldsets = [
        ('Platform', {'fields': ['platform', 'version', 'build_number']}),
        ('Update Settings', {'fields': ['is_required', 'update_url', 'is_active']}),
        ('Changelog', {'fields': ['changelog']}),
    ]


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """Full admin for in-app notification management."""
    
    list_display = [
        'title', 'notification_type', 'display_format', 'force_update', 'priority',
        'status', 'publish_at', 'expires_at', 'is_active_now', 
        'view_count', 'click_count',
    ]
    list_filter = [
        'notification_type', 'display_format', 'status', 
        'platform', 'force_update', 'priority',
    ]
    search_fields = ['title', 'description']
    ordering = ['-priority', '-publish_at']
    date_hierarchy = 'publish_at'
    
    list_editable = ['status', 'priority', 'force_update']
    
    fieldsets = [
        ('Main Info', {
            'fields': ['title', 'description', 'notification_type', 'display_format']
        }),
        ('Version Info', {
            'fields': ['app_version', 'min_version', 'latest_version', 'force_update'],
            'classes': ['collapse'],
        }),
        ('Media & Action', {
            'fields': ['image_url', 'button_url', 'button_text'],
            'classes': ['collapse'],
        }),
        ('Changelog', {
            'fields': ['changelog'],
            'classes': ['collapse'],
            'description': 'JSON array of strings. Example: ["Added new feature", "Bug fixes"]',
        }),
        ('Publication', {
            'fields': ['publish_at', 'expires_at', 'status']
        }),
        ('Targeting', {
            'fields': ['platform', 'target_audience', 'priority']
        }),
        ('Statistics (read-only)', {
            'fields': ['view_count', 'click_count'],
            'classes': ['collapse'],
        }),
    ]
    
    readonly_fields = ['view_count', 'click_count']
    
    def is_active_now(self, obj):
        """Show if notification is currently active."""
        from django.utils import timezone
        now = timezone.now()
        if obj.status != 'published':
            return format_html('<span style="color: gray;">&#10060; Draft</span>')
        if obj.publish_at > now:
            return format_html('<span style="color: orange;">&#9200; Scheduled</span>')
        if obj.expires_at and obj.expires_at < now:
            return format_html('<span style="color: gray;">&#10060; Expired</span>')
        return format_html('<span style="color: green;">&#9989; Active</span>')
    
    is_active_now.short_description = 'Status now'
    
    actions = ['publish_selected', 'archive_selected', 'duplicate_selected']
    
    def publish_selected(self, request, queryset):
        from django.utils import timezone
        updated = queryset.update(status='published', publish_at=timezone.now())
        self.message_user(request, f'{updated} notification(s) published.')
    publish_selected.short_description = 'Publish selected notifications now'
    
    def archive_selected(self, request, queryset):
        updated = queryset.update(status='archived')
        self.message_user(request, f'{updated} notification(s) archived.')
    archive_selected.short_description = 'Archive selected notifications'
    
    def duplicate_selected(self, request, queryset):
        for notification in queryset:
            notification.pk = None
            notification.status = 'draft'
            notification.title = f'{notification.title} (copy)'
            notification.save()
        self.message_user(request, f'{queryset.count()} notification(s) duplicated.')
    duplicate_selected.short_description = 'Duplicate selected notifications'

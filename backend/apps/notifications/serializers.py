"""
Serializers for Notifications app.
"""
from rest_framework import serializers
from .models import AppVersion, Notification, News


class AppVersionSerializer(serializers.ModelSerializer):
    """Serializer for AppVersion."""

    class Meta:
        model = AppVersion
        fields = [
            'id',
            'platform',
            'version',
            'build_number',
            'is_required',
            'update_url',
            'changelog',
            'is_active',
            'created_at',
        ]


class NewsSerializer(serializers.ModelSerializer):
    """Serializer for news items."""

    class Meta:
        model = News
        fields = [
            'id',
            'title',
            'summary',
            'body',
            'image_url',
            'link_url',
            'link_text',
            'priority',
            'published_at',
        ]


class AppVersionCheckSerializer(serializers.Serializer):
    """Serializer for checking app version."""

    platform = serializers.ChoiceField(choices=['android', 'ios'])
    current_version = serializers.CharField()
    build_number = serializers.IntegerField(required=False, default=0)


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for in-app notifications."""

    is_active = serializers.SerializerMethodField()
    notification_type_display = serializers.CharField(
        source='get_notification_type_display', read_only=True
    )
    display_format_display = serializers.CharField(
        source='get_display_format_display', read_only=True
    )

    class Meta:
        model = Notification
        fields = [
            'id',
            'title',
            'description',
            'notification_type',
            'notification_type_display',
            'display_format',
            'display_format_display',
            'app_version',
            'min_version',
            'latest_version',
            'force_update',
            'image_url',
            'button_url',
            'button_text',
            'changelog',
            'publish_at',
            'expires_at',
            'status',
            'platform',
            'target_audience',
            'priority',
            'is_active',
        ]

    def get_is_active(self, obj):
        return obj.is_active()


class NotificationListSerializer(serializers.Serializer):
    """Top-level serializer for the notifications endpoint response."""

    notifications = NotificationSerializer(many=True)
    unread_count = serializers.IntegerField(default=0)


class NotificationAdminSerializer(serializers.ModelSerializer):
    """Full serializer for admin panel."""

    class Meta:
        model = Notification
        fields = '__all__'
        read_only_fields = ['view_count', 'click_count', 'created_at', 'updated_at']


class NotificationStatsSerializer(serializers.Serializer):
    """Serializer for notification statistics."""

    total_notifications = serializers.IntegerField()
    active_notifications = serializers.IntegerField()
    total_views = serializers.IntegerField()
    total_clicks = serializers.IntegerField()

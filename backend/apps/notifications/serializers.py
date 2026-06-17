"""
Serializers for Notifications app.
"""
from rest_framework import serializers
from .models import AppVersion


class AppVersionSerializer(serializers.ModelSerializer):
    """Serializer for AppVersion."""

    class Meta:
        model = AppVersion
        fields = [
            'platform',
            'version',
            'build_number',
            'is_required',
            'update_url',
            'changelog',
            'is_active',
        ]


class AppVersionCheckSerializer(serializers.Serializer):
    """Serializer for checking app version."""

    platform = serializers.ChoiceField(choices=['android', 'ios'])
    current_version = serializers.CharField()
    build_number = serializers.IntegerField(required=False, default=0)

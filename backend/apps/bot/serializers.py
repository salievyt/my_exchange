"""
Serializers for Telegram Bot app.
"""
from rest_framework import serializers
from .models import BotAdmin, BotConfig


class BotAdminSerializer(serializers.ModelSerializer):
    """Serializer for BotAdmin."""
    class Meta:
        model = BotAdmin
        fields = '__all__'
        read_only_fields = ['created_at']


class BotConfigSerializer(serializers.ModelSerializer):
    """Serializer for BotConfig."""
    class Meta:
        model = BotConfig
        fields = '__all__'

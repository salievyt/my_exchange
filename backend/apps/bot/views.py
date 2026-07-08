"""
Views for Telegram Bot app.
"""
from rest_framework import viewsets, permissions
from .models import BotAdmin, BotConfig
from .serializers import BotAdminSerializer, BotConfigSerializer


class IsAdminUser(permissions.BasePermission):
    """Permission for admin users only."""
    def has_permission(self, request, view):
        return request.user and request.user.is_staff


class BotAdminViewSet(viewsets.ModelViewSet):
    """ViewSet for managing bot admins."""
    queryset = BotAdmin.objects.all()
    serializer_class = BotAdminSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    search_fields = ['telegram_id', 'username', 'first_name', 'last_name']


class BotConfigViewSet(viewsets.ModelViewSet):
    """ViewSet for managing bot configuration."""
    queryset = BotConfig.objects.all()
    serializer_class = BotConfigSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminUser]
    search_fields = ['key', 'description']

"""
Views for User app.
"""
import logging

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import LoginHistory, Role
from .serializers import (
    UserSerializer, UserCreateSerializer, UserUpdateSerializer,
    ChangePasswordSerializer, LoginHistorySerializer,
    CustomTokenObtainPairSerializer
)

User = get_user_model()
logger = logging.getLogger(__name__)


class CustomTokenObtainPairView(TokenObtainPairView):
    """Custom login view with user data."""
    serializer_class = CustomTokenObtainPairSerializer
    
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        
        if response.status_code == 200:
            try:
                user_id = response.data.get('user', {}).get('id')
                user = User.objects.get(id=user_id)
                LoginHistory.objects.create(
                    user=user,
                    ip_address=self.get_client_ip(request),
                    user_agent=request.META.get('HTTP_USER_AGENT', '')
                )
            except Exception:
                logger.exception('Failed to create login history entry')
        
        return response
    
    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class CustomTokenRefreshView(TokenRefreshView):
    """Custom token refresh view."""
    pass


class UserViewSet(viewsets.ModelViewSet):
    """ViewSet for user management."""
    
    queryset = User.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return UserUpdateSerializer
        return UserSerializer
    
    def get_permissions(self):
        """Admin-only for user management."""
        if self.action in ['create', 'list', 'retrieve', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsAdminOrReadOnly()]
        return [permissions.IsAuthenticated()]
    
    def get_queryset(self):
        """Filter users based on role."""
        user = self.request.user
        queryset = User.objects.all()
        
        if user.role == Role.ADMIN:
            return queryset
        elif user.role == Role.SENIOR_CASHIER:
            return queryset.exclude(role=Role.ADMIN)
        else:
            return queryset.filter(id=user.id)
    
    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """Change user password."""
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            if not user.check_password(serializer.validated_data['old_password']):
                return Response(
                    {"old_password": "Неверный пароль"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({"message": "Пароль успешно изменен"})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user info."""
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def logout(self, request):
        """Logout user and deactivate session."""
        LoginHistory.objects.filter(
            user=request.user,
            is_active=True
        ).update(
            logout_time=timezone.now(),
            is_active=False
        )
        return Response({"message": "Выход выполнен успешно"})


class IsAdminOrReadOnly(permissions.BasePermission):
    """Permission class for admin-only write access."""
    
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return request.user and request.user.role == Role.ADMIN


class LoginHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for login history (admin only)."""
    
    serializer_class = LoginHistorySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == Role.ADMIN:
            return LoginHistory.objects.all()
        return LoginHistory.objects.filter(user=user)

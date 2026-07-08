"""
Views for Logs app.
"""
from rest_framework import viewsets, permissions
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from .models import AuditLog, ActionType
from .serializers import AuditLogSerializer
from apps.users.models import Role


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing audit logs."""
    
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ['action', 'user', 'model_name']
    search_fields = ['user__username', 'ip_address', 'details']
    ordering_fields = ['timestamp']
    ordering = ['-timestamp']
    
    def get_queryset(self):
        user = self.request.user
        
        # Admin sees all logs
        if user.role == Role.ADMIN:
            return AuditLog.objects.select_related('user').all()
        
        # Senior cashier sees logs except admin actions
        elif user.role == Role.SENIOR_CASHIER:
            return AuditLog.objects.select_related('user').exclude(
                user__role=Role.ADMIN
            )
        
        # Cashier sees only own logs
        else:
            return AuditLog.objects.filter(user=user)

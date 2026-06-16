"""
Views for Currency app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.utils import timezone
from .models import Currency, ExchangeRate, CurrencyRateHistory
from apps.users.models import Role
from .serializers import (
    CurrencySerializer, CurrencyCreateSerializer,
    ExchangeRateSerializer, ExchangeRateCreateSerializer,
    CurrencyRateHistorySerializer
)


class CurrencyViewSet(viewsets.ModelViewSet):
    """ViewSet for currency management."""
    
    queryset = Currency.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CurrencyCreateSerializer
        return CurrencySerializer
    
    def get_permissions(self):
        """Only admin can create/update/delete currencies."""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsAdminOnly()]
        return [permissions.IsAuthenticated()]
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active currencies with current rates."""
        currencies = self.get_queryset().filter(is_active=True)
        serializer = self.get_serializer(currencies, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def history(self, request, pk=None):
        """Get rate history for a currency."""
        currency = self.get_object()
        history = CurrencyRateHistory.objects.filter(currency=currency)
        serializer = CurrencyRateHistorySerializer(history, many=True)
        return Response(serializer.data)


class ExchangeRateViewSet(viewsets.ModelViewSet):
    """ViewSet for exchange rate management."""
    
    serializer_class = ExchangeRateSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = ExchangeRate.objects.all()
        
        # Filter by currency
        currency = self.request.query_params.get('currency')
        if currency:
            queryset = queryset.filter(currency_id=currency)
        
        # Filter by operation type
        operation_type = self.request.query_params.get('operation_type')
        if operation_type:
            queryset = queryset.filter(operation_type=operation_type)
        
        # Only active rates by default
        if not self.request.query_params.get('include_inactive'):
            queryset = queryset.filter(is_active=True)
        
        return queryset
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ExchangeRateCreateSerializer
        return ExchangeRateSerializer
    
    def get_permissions(self):
        """Admin and senior cashier can manage rates."""
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsAdminOrSeniorCashier()]
        return [permissions.IsAuthenticated()]
    
    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """Create new exchange rate with history tracking."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Get existing active rate for history
        currency_id = request.data.get('currency')
        operation_type = request.data.get('operation_type')
        new_rate = serializer.validated_data['rate']
        
        existing_rate = ExchangeRate.objects.filter(
            currency_id=currency_id,
            operation_type=operation_type,
            is_active=True
        ).first()
        
        # Create new rate
        self.perform_create(serializer)
        
        # Create history record if there was an existing rate
        if existing_rate:
            CurrencyRateHistory.objects.create(
                currency_id=currency_id,
                old_rate=existing_rate.rate,
                new_rate=new_rate,
                operation_type=operation_type,
                changed_by=request.user,
                comment=request.data.get('comment', '')
            )
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class CurrencyRateHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing rate change history."""
    
    serializer_class = CurrencyRateHistorySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = CurrencyRateHistory.objects.all()
        
        # Filter by currency
        currency = self.request.query_params.get('currency')
        if currency:
            queryset = queryset.filter(currency_id=currency)
        
        return queryset


class IsAdminOnly(permissions.BasePermission):
    """Permission class for admin only."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role == Role.ADMIN


class IsAdminOrSeniorCashier(permissions.BasePermission):
    """Permission class for admin or senior cashier."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role in [Role.ADMIN, Role.SENIOR_CASHIER]

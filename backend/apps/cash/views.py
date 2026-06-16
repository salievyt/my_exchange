"""
Views for Cash app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
import json
from .models import CashBalance, CashTransaction, CashRegister, CashTransactionType
from .serializers import CashBalanceSerializer, CashTransactionSerializer, CashTransactionCreateSerializer, CashRegisterSerializer
from apps.users.models import Role


class CashBalanceViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing cash balances."""
    
    serializer_class = CashBalanceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return CashBalance.objects.select_related('currency').all()
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Get cash balance summary."""
        balances = self.get_queryset()
        serializer = self.get_serializer(balances, many=True)
        
        total_kgs = sum(
            float(b.balance) for b in balances if b.currency.code == 'KGS'
        )
        
        return Response({
            'balances': serializer.data,
            'total_kgs': total_kgs,
            'currencies_count': balances.count()
        })
    
    @action(detail=False, methods=['get'])
    def low_balance(self, request):
        """Get currencies with low balance."""
        threshold = float(request.query_params.get('threshold', 1000))
        low_balances = CashBalance.objects.filter(balance__lt=threshold)
        serializer = self.get_serializer(low_balances, many=True)
        return Response(serializer.data)


class CashTransactionViewSet(viewsets.ModelViewSet):
    """ViewSet for cash transactions."""
    
    permission_classes = [permissions.IsAuthenticated]
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CashTransactionCreateSerializer
        return CashTransactionSerializer
    
    def get_queryset(self):
        queryset = CashTransaction.objects.select_related('currency', 'cashier').all()
        
        # Filter by user role
        user = self.request.user
        if user.role == Role.CASHIER:
            queryset = queryset.filter(cashier=user)
        
        # Filter by type
        transaction_type = self.request.query_params.get('transaction_type')
        if transaction_type:
            queryset = queryset.filter(transaction_type=transaction_type)
        
        # Filter by currency
        currency = self.request.query_params.get('currency')
        if currency:
            queryset = queryset.filter(currency_id=currency)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        
        return queryset
    
    def get_permissions(self):
        if self.action == 'create':
            return [permissions.IsAuthenticated()]
        elif self.action in ['update', 'partial_update', 'destroy']:
            return [permissions.IsAuthenticated(), IsSeniorCashierOrAdmin()]
        return [permissions.IsAuthenticated()]
    
    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """Create cash transaction and update balance."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        currency = serializer.validated_data['currency']
        amount = serializer.validated_data['amount']
        transaction_type = serializer.validated_data['transaction_type']
        
        # Get or create cash balance
        cash_balance, _ = CashBalance.objects.get_or_create(
            currency=currency,
            defaults={'balance': 0}
        )
        
        balance_before = cash_balance.balance
        
        # Update balance
        if transaction_type == CashTransactionType.DEPOSIT:
            cash_balance.balance += amount
        else:  # WITHDRAWAL or INKASSATION
            cash_balance.balance -= amount
        
        balance_after = cash_balance.balance
        
        # Save balance
        cash_balance.save()
        
        # Create transaction
        transaction = CashTransaction.objects.create(
            cashier=request.user,
            balance_before=balance_before,
            balance_after=balance_after,
            **serializer.validated_data
        )
        
        return Response(
            CashTransactionSerializer(transaction).data,
            status=status.HTTP_201_CREATED
        )


class CashRegisterViewSet(viewsets.ModelViewSet):
    """ViewSet for cash register (shift) management."""
    
    serializer_class = CashRegisterSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = CashRegister.objects.select_related('cashier').all()
        user = self.request.user
        
        if user.role == Role.CASHIER:
            queryset = queryset.filter(cashier=user)
        
        return queryset
    
    @action(detail=False, methods=['post'])
    def open(self, request):
        """Open new cash register session."""
        # Check if user already has open register
        existing = CashRegister.objects.filter(
            cashier=request.user,
            is_open=True
        ).first()
        
        if existing:
            return Response(
                {"error": "У вас уже есть открытая смена"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get opening balances
        opening_balances = {}
        balances = CashBalance.objects.all()
        for balance in balances:
            opening_balances[balance.currency.code] = float(balance.balance)
        
        # Create register
        register = CashRegister.objects.create(
            cashier=request.user,
            opening_balance=json.dumps(opening_balances),
            comment=request.data.get('comment', '')
        )
        
        return Response(
            CashRegisterSerializer(register).data,
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['post'])
    def close(self, request, pk=None):
        """Close cash register session."""
        register = self.get_object()
        
        if not register.is_open:
            return Response(
                {"error": "Смена уже закрыта"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get closing balances
        closing_balances = {}
        balances = CashBalance.objects.all()
        for balance in balances:
            closing_balances[balance.currency.code] = float(balance.balance)
        
        # Close register
        register.closing_balance = json.dumps(closing_balances)
        register.closed_at = timezone.now()
        register.is_open = False
        register.comment = request.data.get('comment', register.comment)
        register.save()
        
        return Response(CashRegisterSerializer(register).data)
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """Get current open register for user."""
        register = CashRegister.objects.filter(
            cashier=request.user,
            is_open=True
        ).first()
        
        if not register:
            return Response({"message": "Нет открытой смены"})
        
        return Response(CashRegisterSerializer(register).data)


class IsSeniorCashierOrAdmin(permissions.BasePermission):
    """Permission for senior cashier and admin."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role in [Role.SENIOR_CASHIER, Role.ADMIN]

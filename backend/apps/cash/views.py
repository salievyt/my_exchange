"""
Views for Cash app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Sum, Avg, Q
from django.utils import timezone
import json
from decimal import Decimal
from .models import CashBalance, CashTransaction, CashRegister, CashTransactionType
from .serializers import CashBalanceSerializer, CashTransactionSerializer, CashTransactionCreateSerializer, CashRegisterSerializer
from apps.currencies.models import Currency
from apps.users.models import Role
from apps.operations.models import Operation, OperationType, OperationStatus


class CashBalanceViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for viewing cash balances."""
    
    serializer_class = CashBalanceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return CashBalance.objects.select_related('currency').all().order_by('id')
    
    def _get_ops_balance(self, request):
        """Calculate balance_from_operations for each currency.
        Returns dict {currency_code: balance_from_operations}.
        """
        current_register = CashRegister.objects.filter(
            cashier=request.user,
            is_open=True
        ).first()
        
        ops_balance = {}
        
        if not current_register:
            return ops_balance
        
        # Get opening balances from register
        if current_register.opening_balance:
            try:
                opening_balances = json.loads(current_register.opening_balance)
            except (json.JSONDecodeError, TypeError):
                opening_balances = {}
        else:
            opening_balances = {}
        
        shift_start = current_register.opened_at
        
        # Single aggregated query for all currencies
        ops = Operation.objects.filter(
            created_at__gte=shift_start,
            status=OperationStatus.ACTIVE,
        )
        if request.user.role == Role.CASHIER:
            ops = ops.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            ops = ops.exclude(cashier__role=Role.ADMIN)
        
        # Aggregate buy and sell sums per currency in one query
        ops_agg = ops.values('currency__code').annotate(
            buy_sum=Sum('amount', filter=Q(operation_type=OperationType.BUY)),
            sell_sum=Sum('amount', filter=Q(operation_type=OperationType.SELL)),
        )
        
        ops_summary = {
            entry['currency__code']: float(entry['buy_sum'] or 0) - float(entry['sell_sum'] or 0)
            for entry in ops_agg
        }
        
        # Combine all currency codes from opening and operations
        all_codes = set(opening_balances.keys()) | set(ops_summary.keys())
        for code in all_codes:
            opening = opening_balances.get(code, 0)
            ops_net = ops_summary.get(code, 0)
            ops_balance[code] = round(opening + ops_net, 2)
        
        return ops_balance
    
    def list(self, request, *args, **kwargs):
        """List balances with balance_from_operations calculation."""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Calculate ops balances once, pass via serializer context
        ops_balance = self._get_ops_balance(request)
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True, context={'ops_balance': ops_balance})
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True, context={'ops_balance': ops_balance})
        return Response(serializer.data)
    
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
    
    @action(detail=False, methods=['get'])
    def average_rates(self, request):
        """Get average rates for each currency since the current shift opened."""
        from apps.cash.models import CashRegister
        
        now = timezone.now()
        today = now.date()
        
        # Find user's current shift start time
        current_register = CashRegister.objects.filter(
            cashier=request.user,
            is_open=True
        ).first()
        
        if not current_register:
            return Response({'average_rates': {}, 'shift_open': False})
        
        shift_start = current_register.opened_at
        
        # Get all buy operations since shift start (they add to inventory)
        buy_ops = Operation.objects.filter(
            operation_type=OperationType.BUY,
            status=OperationStatus.ACTIVE,
            created_at__gte=shift_start,
        )
        
        # Role filtering
        if request.user.role == Role.CASHIER:
            buy_ops = buy_ops.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            buy_ops = buy_ops.exclude(cashier__role=Role.ADMIN)
        
        # Calculate average buy rate per currency (weighted by amount)
        # Average rate = Sum(total_amount) / Sum(amount) for buy operations
        rates_data = buy_ops.values('currency__code').annotate(
            total_amount=Sum('amount'),
            total_kgs=Sum('total_amount'),
        )
        
        average_rates = {}
        for entry in rates_data:
            code = entry['currency__code']
            total_amt = float(entry['total_amount'] or 0)
            total_kgs = float(entry['total_kgs'] or 0)
            if total_amt > 0:
                avg_rate = round(total_kgs / total_amt, 4)
                average_rates[code] = avg_rate
        
        # Calculate KGS equivalent for each balance and total
        balances = CashBalance.objects.select_related('currency').all()
        currency_breakdown = []
        total_kgs = 0.0
        
        for bal in balances:
            code = bal.currency.code
            balance_amount = float(bal.balance)
            avg_rate = average_rates.get(code)
            
            if code == 'KGS':
                kgs_equivalent = balance_amount
                currency_breakdown.append({
                    'currency': code,
                    'balance': balance_amount,
                    'average_rate': 1.0,
                    'kgs_equivalent': round(balance_amount, 2),
                })
                total_kgs += balance_amount
            elif avg_rate and balance_amount > 0:
                kgs_eq = round(balance_amount * avg_rate, 2)
                currency_breakdown.append({
                    'currency': code,
                    'balance': balance_amount,
                    'average_rate': avg_rate,
                    'kgs_equivalent': kgs_eq,
                })
                total_kgs += kgs_eq
            else:
                currency_breakdown.append({
                    'currency': code,
                    'balance': balance_amount,
                    'average_rate': avg_rate or 0,
                    'kgs_equivalent': 0,
                })
        
        return Response({
            'average_rates': average_rates,
            'shift_open': True,
            'shift_started_at': shift_start.isoformat(),
            'currency_breakdown': currency_breakdown,
            'total_kgs': round(total_kgs, 2),
        })


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
    @transaction.atomic
    def open(self, request):
        """Open new cash register session with opening balances."""
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
        
        # Get opening balances from request
        opening_balance_data = request.data.get('opening_balance', {})
        if not opening_balance_data or not isinstance(opening_balance_data, dict):
            return Response(
                {"error": "Не указаны начальные остатки"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update CashBalance records with opening balances
        opening_balances = {}
        for currency_code, amount in opening_balance_data.items():
            try:
                amount = float(amount)
            except (TypeError, ValueError):
                continue
            if amount < 0:
                continue
            currency = Currency.objects.filter(code=currency_code).first()
            if currency:
                decimal_amount = Decimal(str(amount))
                cash_balance, created = CashBalance.objects.get_or_create(
                    currency=currency,
                    defaults={'balance': decimal_amount}
                )
                if not created:
                    cash_balance.balance = decimal_amount
                    cash_balance.save()
                opening_balances[currency_code] = amount
        
        if not opening_balances:
            return Response(
                {"error": "Не указаны корректные начальные остатки"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
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
    @transaction.atomic
    def close(self, request, pk=None):
        """Close cash register session with closing balances."""
        register = self.get_object()
        
        if not register.is_open:
            return Response(
                {"error": "Смена уже закрыта"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get closing balances from request
        closing_balance_data = request.data.get('closing_balance', {})
        if not closing_balance_data or not isinstance(closing_balance_data, dict):
            return Response(
                {"error": "Не указаны конечные остатки"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update CashBalance records with closing balances
        closing_balances = {}
        for currency_code, amount in closing_balance_data.items():
            try:
                amount = float(amount)
            except (TypeError, ValueError):
                continue
            if amount < 0:
                continue
            currency = Currency.objects.filter(code=currency_code).first()
            if currency:
                decimal_amount = Decimal(str(amount))
                cash_balance, created = CashBalance.objects.get_or_create(
                    currency=currency,
                    defaults={'balance': decimal_amount}
                )
                if not created:
                    cash_balance.balance = decimal_amount
                    cash_balance.save()
                closing_balances[currency_code] = amount
        
        if not closing_balances:
            return Response(
                {"error": "Не указаны корректные конечные остатки"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
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

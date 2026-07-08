"""
Views for Operation app.
"""
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Sum, Q
from django.utils import timezone
from .models import Operation, OperationEditHistory, OperationCancellation, OperationStatus, OperationType
from .serializers import (
    OperationSerializer, OperationCreateSerializer, OperationUpdateSerializer,
    OperationEditHistorySerializer, OperationCancellationSerializer
)
from apps.cash.models import CashBalance
from apps.currencies.models import Currency
from apps.users.models import Role


class OperationViewSet(viewsets.ModelViewSet):
    """ViewSet for operation management."""
    
    permission_classes = [permissions.IsAuthenticated]
    search_fields = ['operation_number', 'client_name', 'comment']
    ordering_fields = ['created_at', 'amount', 'total_amount', 'rate']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return OperationCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return OperationUpdateSerializer
        return OperationSerializer
    
    def get_queryset(self):
        queryset = Operation.objects.all()
        user = self.request.user
        
        # Filter based on user role
        if user.role == Role.CASHIER:
            queryset = queryset.filter(cashier=user)
        elif user.role == Role.SENIOR_CASHIER:
            queryset = queryset.exclude(cashier__role=Role.ADMIN)
        # Admin sees all
        
        # Filter by status
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        
        # Filter by operation type
        operation_type = self.request.query_params.get('operation_type')
        if operation_type:
            queryset = queryset.filter(operation_type=operation_type)
        
        # Filter by currency
        currency = self.request.query_params.get('currency')
        if currency:
            queryset = queryset.filter(currency_id=currency)
        
        # Filter by cashier
        cashier = self.request.query_params.get('cashier')
        if cashier:
            queryset = queryset.filter(cashier_id=cashier)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        if date_from:
            queryset = queryset.filter(created_at__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(created_at__date__lte=date_to)
        
        # Filter by amount range
        amount_from = self.request.query_params.get('amount_from')
        amount_to = self.request.query_params.get('amount_to')
        if amount_from:
            queryset = queryset.filter(amount__gte=amount_from)
        if amount_to:
            queryset = queryset.filter(amount__lte=amount_to)
        
        return queryset
    
    def get_permissions(self):
        """Senior cashier and admin can update/delete operations."""
        if self.action in ['update', 'partial_update', 'destroy', 'cancel']:
            return [permissions.IsAuthenticated(), IsSeniorCashierOrAdmin()]
        return [permissions.IsAuthenticated()]
    
    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """Create new operation with cash balance update."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        operation_type = serializer.validated_data['operation_type']
        currency = serializer.validated_data['currency']
        amount = serializer.validated_data['amount']
        rate = serializer.validated_data.get('rate', 0)
        total_amount = float(amount) * float(rate)
        
        # Check cash balance based on operation type
        if operation_type == OperationType.SELL:
            cash_balance = CashBalance.objects.filter(currency=currency).first()
            if not cash_balance or cash_balance.balance < amount:
                return Response(
                    {"error": "Недостаточно валюты в кассе"},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        elif operation_type == OperationType.BUY:
            # Buying foreign currency - need enough KGS (som) in cash
            kgs_currency = Currency.objects.filter(code='KGS').first()
            if kgs_currency:
                kgs_balance = CashBalance.objects.filter(currency=kgs_currency).first()
                if not kgs_balance or kgs_balance.balance < total_amount:
                    return Response(
                        {"error": "Недостаточно сом (KGS) в кассе для покупки валюты"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
        # Create operation
        self.perform_create(serializer)
        
        # Update cash balance
        self._update_cash_balance(operation_type, currency, amount, total_amount)
        
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def _update_cash_balance(self, operation_type, currency, amount, total_amount):
        """Update cash balance based on operation type."""
        cash_balance, created = CashBalance.objects.get_or_create(
            currency=currency,
            defaults={'balance': 0}
        )
        
        # Also update KGS (som) balance
        # When buying, we give KGS to client (KGS decreases)
        # When selling, we receive KGS from client (KGS increases)
        kgs_currency = Currency.objects.filter(code='KGS').first()
        if kgs_currency:
            # Use the total_amount passed from create method
            total_amount_kgs = total_amount
            
            kgs_balance, created = CashBalance.objects.get_or_create(
                currency=kgs_currency,
                defaults={'balance': 0}
            )
            
            if operation_type == OperationType.BUY:
                # Giving KGS to client
                kgs_balance.balance -= total_amount_kgs
            else:
                # Receiving KGS from client
                kgs_balance.balance += total_amount_kgs
            
            kgs_balance.save()

        if operation_type == OperationType.BUY:
            # Buying from client = adding to cash
            cash_balance.balance += amount
        else:
            # Selling to client = subtracting from cash
            cash_balance.balance -= amount
        
        cash_balance.save()
    
    @transaction.atomic
    def update(self, request, *args, **kwargs):
        """Update operation with history tracking."""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Track changes
        for field, value in request.data.items():
            if field in ['amount', 'rate', 'comment', 'client_name', 'client_company']:
                old_value = getattr(instance, field)
                if str(old_value) != str(value):
                    OperationEditHistory.objects.create(
                        operation=instance,
                        edited_by=request.user,
                        field_changed=field,
                        old_value=str(old_value),
                        new_value=str(value),
                        comment=request.data.get('edit_comment', '')
                    )
        
        # Recalculate total if amount or rate changed
        if 'amount' in request.data or 'rate' in request.data:
            amount = request.data.get('amount', instance.amount)
            rate = request.data.get('rate', instance.rate)
            request.data['total_amount'] = float(amount) * float(rate)
        
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel operation (full or partial)."""
        operation = self.get_object()
        
        if operation.status == OperationStatus.CANCELLED:
            return Response(
                {"error": "Операция уже отменена"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        cancellation_type = request.data.get('cancellation_type', 'full')
        cancel_amount = request.data.get('cancel_amount')
        reason = request.data.get('reason', '')
        
        if not reason:
            return Response(
                {"reason": "Причина отмены обязательна"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if cancellation_type == 'partial' and not cancel_amount:
            return Response(
                {"cancel_amount": "Сумма отмены обязательна для частичной отмены"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with transaction.atomic():
            # Create cancellation record
            cancellation = OperationCancellation.objects.create(
                operation=operation,
                cancelled_by=request.user,
                cancellation_type=cancellation_type,
                cancel_amount=cancel_amount,
                reason=reason
            )

            # Get or create cash balance for the operation's currency
            cash_balance, _ = CashBalance.objects.get_or_create(
                currency=operation.currency,
                defaults={'balance': 0}
            )

            # Update operation status and reverse cash balance
            if cancellation_type == 'full':
                operation.status = OperationStatus.CANCELLED
                # Reverse cash balance
                if operation.operation_type == OperationType.BUY:
                    cash_balance.balance -= operation.amount
                else:
                    cash_balance.balance += operation.amount
                cash_balance.save()
                operation.save()
            else:
                operation.status = OperationStatus.PARTIALLY_CANCELLED
                # Update operation amount
                operation.amount -= cancel_amount
                operation.total_amount = operation.amount * operation.rate
                operation.save()
        
        return Response({
            "message": "Операция отменена",
            "cancellation": OperationCancellationSerializer(cancellation).data
        })
    
    @action(detail=True, methods=['get'])
    def history(self, request, pk=None):
        """Get edit history for operation."""
        operation = self.get_object()
        history = operation.edit_history.all()
        serializer = OperationEditHistorySerializer(history, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def today_stats(self, request):
        """Get today's operation statistics."""
        today = timezone.now().date()
        operations = Operation.objects.filter(created_at__date=today)

        # Filter by user role
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)

        active_ops = operations.filter(status=OperationStatus.ACTIVE)
        buy_ops = active_ops.filter(operation_type=OperationType.BUY)
        sell_ops = active_ops.filter(operation_type=OperationType.SELL)

        buy_amount = buy_ops.aggregate(total=Sum('amount'))['total'] or 0
        sell_amount = sell_ops.aggregate(total=Sum('amount'))['total'] or 0

        stats = {
            'total_operations': operations.count(),
            'buy_operations': buy_ops.count(),
            'sell_operations': sell_ops.count(),
            'buy_count': buy_ops.count(),
            'sell_count': sell_ops.count(),
            'buy_amount': float(buy_amount),
            'sell_amount': float(sell_amount),
            'total_amount': float(active_ops.aggregate(
                total=Sum('total_amount')
            )['total'] or 0),
            'cancelled_count': operations.filter(
                status=OperationStatus.CANCELLED
            ).count(),
        }

        return Response(stats)


class IsSeniorCashierOrAdmin(permissions.BasePermission):
    """Permission for senior cashier and admin."""
    
    def has_permission(self, request, view):
        return request.user and request.user.role in [Role.SENIOR_CASHIER, Role.ADMIN]

"""
Views for Analytics app.
Provides statistics and charts data.
"""
from rest_framework import views, permissions
from rest_framework.response import Response
from django.db.models import Sum, Count, Avg, Q
from django.utils import timezone
from datetime import timedelta, date
from apps.operations.models import Operation, OperationStatus, OperationType
from apps.cash.models import CashBalance
from apps.currencies.models import Currency
from apps.users.models import Role, User


class DashboardStatsView(views.APIView):
    """Get dashboard statistics for main panel."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        today = timezone.now().date()
        
        # Filter operations for today
        operations = Operation.objects.filter(
            created_at__date=today,
            status=OperationStatus.ACTIVE
        )
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        # Calculate stats
        stats = {
            'operations_today': operations.count(),
            'buy_operations': operations.filter(operation_type=OperationType.BUY).count(),
            'sell_operations': operations.filter(operation_type=OperationType.SELL).count(),
            'turnover_today': operations.aggregate(total=Sum('total_amount'))['total'] or 0,
            'clients_today': operations.values('client_name').distinct().count(),
        }
        
        # Get current exchange rates
        rates = []
        for currency in Currency.objects.filter(is_active=True):
            buy_rate = currency.exchange_rates.filter(
                operation_type='buy',
                is_active=True
            ).first()
            sell_rate = currency.exchange_rates.filter(
                operation_type='sell',
                is_active=True
            ).first()
            
            if buy_rate or sell_rate:
                rates.append({
                    'currency': currency.code,
                    'currency_name': currency.name,
                    'buy': float(buy_rate.rate) if buy_rate else None,
                    'sell': float(sell_rate.rate) if sell_rate else None,
                })
        
        stats['exchange_rates'] = rates
        
        # Get cash balances
        balances = CashBalance.objects.select_related('currency').all()
        stats['cash_balances'] = [
            {
                'currency': b.currency.code,
                'balance': float(b.balance),
                'available': float(b.available_balance),
            }
            for b in balances
        ]
        
        return Response(stats)


class AnalyticsOperationsView(views.APIView):
    """Get analytics data for operations charts."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        period = request.query_params.get('period', '7')  # days
        period_start = timezone.now().date() - timedelta(days=int(period))
        
        # Filter operations
        operations = Operation.objects.filter(
            created_at__date__gte=period_start,
            status=OperationStatus.ACTIVE
        )
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        # Daily breakdown for charts
        daily_data = []
        for i in range(int(period)):
            current_date = period_start + timedelta(days=i)
            day_ops = operations.filter(created_at__date=current_date)
            
            buy_ops = day_ops.filter(operation_type=OperationType.BUY)
            sell_ops = day_ops.filter(operation_type=OperationType.SELL)
            
            daily_data.append({
                'date': str(current_date),
                'operations': day_ops.count(),
                'buy_count': buy_ops.count(),
                'sell_count': sell_ops.count(),
                'buy_amount': buy_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
                'sell_amount': sell_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            })
        
        # Currency popularity
        currency_stats = []
        for currency in Currency.objects.all():
            currency_ops = operations.filter(currency=currency)
            currency_stats.append({
                'currency': currency.code,
                'operations': currency_ops.count(),
                'total_amount': currency_ops.aggregate(total=Sum('amount'))['total'] or 0,
                'turnover': currency_ops.aggregate(total=Sum('total_amount'))['total'] or 0,
            })
        
        # Sort by operations count
        currency_stats.sort(key=lambda x: x['operations'], reverse=True)
        
        return Response({
            'daily_data': daily_data,
            'currency_stats': currency_stats[:10],  # Top 10
        })


class AnalyticsProfitabilityView(views.APIView):
    """Get profitability analytics."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        period = request.query_params.get('period', '30')  # days
        period_start = timezone.now().date() - timedelta(days=int(period))
        
        operations = Operation.objects.filter(
            created_at__date__gte=period_start,
            status=OperationStatus.ACTIVE
        )
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        # Calculate profitability by currency
        profitability = []
        for currency in Currency.objects.all():
            buy_ops = operations.filter(
                currency=currency,
                operation_type=OperationType.BUY
            )
            sell_ops = operations.filter(
                currency=currency,
                operation_type=OperationType.SELL
            )
            
            buy_total = buy_ops.aggregate(total=Sum('total_amount'))['total'] or 0
            sell_total = sell_ops.aggregate(total=Sum('total_amount'))['total'] or 0
            buy_amount = buy_ops.aggregate(total=Sum('amount'))['total'] or 0
            sell_amount = sell_ops.aggregate(total=Sum('amount'))['total'] or 0
            
            # Calculate spread (profit)
            spread = sell_total - buy_total if buy_total > 0 else 0
            spread_percent = (spread / buy_total * 100) if buy_total > 0 else 0
            
            profitability.append({
                'currency': currency.code,
                'buy_turnover': float(buy_total),
                'sell_turnover': float(sell_total),
                'buy_amount': float(buy_amount),
                'sell_amount': float(sell_amount),
                'spread': float(spread),
                'spread_percent': round(spread_percent, 2),
            })
        
        return Response({
            'period_days': int(period),
            'profitability': profitability,
        })


class ShiftCurrencyStatsView(views.APIView):
    """Get per-currency operation stats since the start of the user's current shift."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        from apps.cash.models import CashRegister
        
        # Find user's current shift
        current_register = CashRegister.objects.filter(
            cashier=request.user,
            is_open=True
        ).first()
        
        if not current_register:
            return Response({'shift_stats': [], 'shift_open': False, 'message': 'Нет открытой смены'})
        
        shift_start = current_register.opened_at
        
        # Filter operations since shift start
        operations = Operation.objects.filter(
            created_at__gte=shift_start,
            status=OperationStatus.ACTIVE
        )
        
        # Role-based filtering
        if request.user.role == Role.CASHIER:
            operations = operations.filter(cashier=request.user)
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        
        # Per-currency stats
        shift_stats = []
        for currency in Currency.objects.filter(is_active=True).exclude(code='KGS'):
            currency_ops = operations.filter(currency=currency)
            
            buy_ops = currency_ops.filter(operation_type=OperationType.BUY)
            sell_ops = currency_ops.filter(operation_type=OperationType.SELL)
            
            buy_amount = float(buy_ops.aggregate(total=Sum('amount'))['total'] or 0)
            sell_amount = float(sell_ops.aggregate(total=Sum('amount'))['total'] or 0)
            
            avg_buy_rate = buy_ops.aggregate(avg=Avg('rate'))['avg']
            avg_sell_rate = sell_ops.aggregate(avg=Avg('rate'))['avg']
            
            # Calculate KGS equivalents using average rates (as requested by user)
            buy_total_kgs = round(buy_amount * float(avg_buy_rate), 2) if avg_buy_rate else 0
            sell_total_kgs = round(sell_amount * float(avg_sell_rate), 2) if avg_sell_rate else 0
            
            if buy_amount > 0 or sell_amount > 0:
                shift_stats.append({
                    'currency': currency.code,
                    'currency_name': currency.name,
                    'buy_amount': round(buy_amount, 2),
                    'sell_amount': round(sell_amount, 2),
                    'buy_total_kgs': round(buy_total_kgs, 2),
                    'sell_total_kgs': round(sell_total_kgs, 2),
                    'avg_buy_rate': round(float(avg_buy_rate), 4) if avg_buy_rate else 0,
                    'avg_sell_rate': round(float(avg_sell_rate), 4) if avg_sell_rate else 0,
                })
        
        return Response({
            'shift_open': True,
            'shift_started_at': shift_start.isoformat(),
            'shift_stats': shift_stats,
        })


class CashierLoadView(views.APIView):
    """Get cashier workload analytics."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        period = request.query_params.get('period', '7')  # days
        period_start = timezone.now().date() - timedelta(days=int(period))
        
        operations = Operation.objects.filter(
            created_at__date__gte=period_start,
            status=OperationStatus.ACTIVE
        )
        
        # Admin sees all, senior sees non-admin cashiers
        if request.user.role == Role.ADMIN:
            pass
        elif request.user.role == Role.SENIOR_CASHIER:
            operations = operations.exclude(cashier__role=Role.ADMIN)
        else:
            operations = operations.filter(cashier=request.user)
        
        # Cashier statistics
        cashier_stats = []
        cashiers = operations.values(
            'cashier', 'cashier__username',
            'cashier__first_name', 'cashier__last_name'
        ).annotate(
            ops_count=Count('id'),
            total_turnover=Sum('total_amount'),
            avg_operation=Avg('total_amount')
        )
        
        for cashier_data in cashiers:
            cashier_stats.append({
                'cashier_id': cashier_data['cashier'],
                'username': cashier_data['cashier__username'],
                'name': f"{cashier_data['cashier__first_name']} {cashier_data['cashier__last_name']}",
                'operations': cashier_data['ops_count'],
                'turnover': float(cashier_data['total_turnover']) if cashier_data['total_turnover'] else 0,
                'avg_operation': float(cashier_data['avg_operation']) if cashier_data['avg_operation'] else 0,
            })
        
        # Sort by operations count
        cashier_stats.sort(key=lambda x: x['operations'], reverse=True)
        
        return Response({
            'period_days': int(period),
            'cashier_stats': cashier_stats,
        })

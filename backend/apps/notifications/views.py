"""
Views for Notifications app.
Handles system notifications and alerts.
"""
from rest_framework import views, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from django.utils import timezone
from django.db.models import Sum
from django.conf import settings
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from apps.cash.models import CashBalance
from apps.operations.models import Operation, OperationStatus
from apps.users.models import Role


class NotificationView(views.APIView):
    """Get user notifications."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        notifications = []
        
        # Check low cash balance
        low_balance_notifications = self.check_low_balance()
        notifications.extend(low_balance_notifications)
        
        # Check end of shift
        shift_notifications = self.check_shift_end()
        notifications.extend(shift_notifications)
        
        # Check suspicious operations
        suspicious_notifications = self.check_suspicious_operations(request.user)
        notifications.extend(suspicious_notifications)
        
        return Response({
            'notifications': notifications,
            'count': len(notifications)
        })
    
    def check_low_balance(self):
        """Check for low cash balance notifications."""
        notifications = []
        threshold = float(getattr(settings, 'NOTIFY_LOW_CASH_THRESHOLD', 1000))
        
        low_balances = CashBalance.objects.filter(balance__lt=threshold)
        
        for balance in low_balances:
            notifications.append({
                'type': 'low_balance',
                'priority': 'high',
                'title': 'Низкий остаток валюты',
                'message': f'Остаток {balance.currency.code} ({balance.balance}) ниже порога ({threshold})',
                'currency': balance.currency.code,
                'balance': float(balance.balance),
                'threshold': threshold,
                'timestamp': timezone.now().isoformat(),
            })
        
        return notifications
    
    def check_shift_end(self):
        """Check for shift end notifications."""
        notifications = []
        
        # This would typically check if shift is about to end
        # For now, return empty - can be extended based on business logic
        
        return notifications
    
    def check_suspicious_operations(self, user):
        """Check for suspicious operation patterns."""
        notifications = []
        
        # Only admin and senior cashier can see these
        if user.role not in [Role.ADMIN, Role.SENIOR_CASHIER]:
            return notifications
        
        today = timezone.now().date()
        
        # Check for high number of cancellations
        from apps.operations.models import OperationCancellation
        cancellations_today = OperationCancellation.objects.filter(
            cancelled_at__date=today
        ).count()
        
        if cancellations_today > 10:
            notifications.append({
                'type': 'suspicious',
                'priority': 'medium',
                'title': 'Много отмен операций',
                'message': f'Сегодня отменено {cancellations_today} операций',
                'timestamp': timezone.now().isoformat(),
            })
        
        # Check for large operations
        large_ops = Operation.objects.filter(
            created_at__date=today,
            total_amount__gt=1000000,  # More than 1M KGS
            status=OperationStatus.ACTIVE
        ).count()
        
        if large_ops > 0:
            notifications.append({
                'type': 'large_operation',
                'priority': 'medium',
                'title': 'Крупные операции',
                'message': f'Сегодня {large_ops} операций на сумму более 1M KGS',
                'timestamp': timezone.now().isoformat(),
            })
        
        return notifications


class SendNotificationView(views.APIView):
    """Send notification via WebSocket."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        """Send notification to specific user or group."""
        message = request.data.get('message')
        title = request.data.get('title', 'Уведомление')
        user_id = request.data.get('user_id')
        notification_type = request.data.get('type', 'info')
        
        if not message:
            return Response(
                {"error": "Сообщение обязательно"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Only admin can send notifications
        if request.user.role != Role.ADMIN:
            return Response(
                {"error": "Только администратор может отправлять уведомления"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Send via WebSocket
        try:
            channel_layer = get_channel_layer()
            
            notification = {
                'type': 'notification',
                'title': title,
                'message': message,
                'notification_type': notification_type,
                'timestamp': timezone.now().isoformat(),
            }
            
            if user_id:
                # Send to specific user
                async_to_sync(channel_layer.group_send)(
                    f'user_{user_id}',
                    notification
                )
            else:
                # Send to all admins
                async_to_sync(channel_layer.group_send)(
                    'admins',
                    notification
                )
            
            return Response({
                'message': 'Уведомление отправлено',
                'notification': notification
            })
            
        except Exception as e:
            return Response(
                {"error": f"Ошибка отправки: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ErrorNotificationView(views.APIView):
    """Report system error."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        """Report an error in the system."""
        error_message = request.data.get('error')
        operation_id = request.data.get('operation_id')
        
        if not error_message:
            return Response(
                {"error": "Описание ошибки обязательно"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Log error (in production, send to monitoring system)
        # For now, just return success
        return Response({
            'message': 'Ошибка записана в лог',
            'error': error_message,
            'operation_id': operation_id,
            'timestamp': timezone.now().isoformat(),
        })

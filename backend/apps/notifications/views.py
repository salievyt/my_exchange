"""
Views for Notifications app.
In-App Notification & Update Center system.
"""
from rest_framework import views, permissions, status, generics
from rest_framework.response import Response
from rest_framework.decorators import action
from django.utils import timezone
from django.db.models import Sum, Q
from django.conf import settings

from .models import AppVersion, Notification, NotificationStatus, Platform
from .serializers import (
    AppVersionSerializer,
    AppVersionCheckSerializer,
    NotificationSerializer,
    NotificationAdminSerializer,
    NotificationStatsSerializer,
)


class AppNotificationsView(views.APIView):
    """
    Main in-app notification endpoint.
    GET /api/v1/app/notifications/
    
    Returns:
    - latest_version: latest app version info
    - min_version: minimum supported version
    - notifications: list of active notifications for this user
    - force_update: whether a mandatory update is required
    """
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        now = timezone.now()
        
        # --- Version info ---
        platform = request.query_params.get('platform', 'android')
        
        # Latest version for this platform
        latest_version = AppVersion.objects.filter(
            platform=platform,
            is_active=True,
        ).order_by('-build_number').first()
        
        # Minimum supported version for this platform
        min_version = AppVersion.objects.filter(
            platform=platform,
            is_active=True,
            is_required=True,
        ).order_by('-build_number').first()
        
        version_info = {
            'latest_version': latest_version.version if latest_version else None,
            'latest_build': latest_version.build_number if latest_version else None,
            'latest_update_url': latest_version.update_url if latest_version else None,
            'latest_changelog': latest_version.changelog if latest_version else '',
            'min_version': min_version.version if min_version else None,
            'min_build': min_version.build_number if min_version else None,
            'force_update': min_version.is_required if min_version else False,
        }
        
        # --- Active notifications ---
        user = request.user
        
        # Base query: published, not expired, publish_at <= now
        notifications_qs = Notification.objects.filter(
            status=NotificationStatus.PUBLISHED,
            publish_at__lte=now,
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gte=now)
        )
        
        # Filter by platform (ALL matches any)
        notifications_qs = notifications_qs.filter(
            Q(platform=Platform.ALL) | Q(platform=platform)
        )
        
        # Filter by target audience (role)
        if user.role:
            notifications_qs = notifications_qs.filter(
                Q(target_audience='') | 
                Q(target_audience__iexact=user.role)
            )
        else:
            notifications_qs = notifications_qs.filter(
                Q(target_audience='')
            )
        
        # Order by priority (highest first), then publish date
        notifications_qs = notifications_qs.order_by('-priority', '-publish_at')
        
        serializer = NotificationSerializer(notifications_qs, many=True)
        
        # Determine if force update is required
        force_update = (
            min_version and 
            request.query_params.get('current_build', '0').isdigit() and
            int(request.query_params.get('current_build', '0')) < min_version.build_number
        )
        
        return Response({
            'version': version_info,
            'notifications': serializer.data,
            'unread_count': len(serializer.data),
            'force_update': force_update,
            'server_time': now.isoformat(),
        })


class NotificationView(views.APIView):
    """Get user notifications (legacy endpoint)."""
    
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
        from apps.cash.models import CashBalance
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
        return []
    
    def check_suspicious_operations(self, user):
        from apps.operations.models import Operation, OperationStatus, OperationCancellation
        from apps.users.models import Role
        notifications = []
        
        if user.role not in [Role.ADMIN, Role.SENIOR_CASHIER]:
            return notifications
        
        today = timezone.now().date()
        
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
        
        large_ops = Operation.objects.filter(
            created_at__date=today,
            total_amount__gt=1000000,
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


class NotificationTrackView(views.APIView):
    """Track notification view or click."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, notification_id):
        try:
            notification = Notification.objects.get(id=notification_id)
        except Notification.DoesNotExist:
            return Response({'error': 'Уведомление не найдено'}, status=status.HTTP_404_NOT_FOUND)
        
        action_type = request.data.get('action', 'view')
        
        if action_type == 'view':
            notification.increment_view()
        elif action_type == 'click':
            notification.increment_click()
        
        return Response({'success': True})


class SendNotificationView(views.APIView):
    """Send notification via WebSocket (legacy)."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        message = request.data.get('message')
        title = request.data.get('title', 'Уведомление')
        user_id = request.data.get('user_id')
        notification_type = request.data.get('type', 'info')
        
        if not message:
            return Response(
                {"error": "Сообщение обязательно"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        from apps.users.models import Role
        if request.user.role != Role.ADMIN:
            return Response(
                {"error": "Только администратор может отправлять уведомления"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            from channels.layers import get_channel_layer
            from asgiref.sync import async_to_sync
            
            channel_layer = get_channel_layer()
            
            notification = {
                'type': 'notification',
                'title': title,
                'message': message,
                'notification_type': notification_type,
                'timestamp': timezone.now().isoformat(),
            }
            
            if user_id:
                async_to_sync(channel_layer.group_send)(
                    f'user_{user_id}',
                    notification
                )
            else:
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
        error_message = request.data.get('error')
        operation_id = request.data.get('operation_id')
        
        if not error_message:
            return Response(
                {"error": "Описание ошибки обязательно"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response({
            'message': 'Ошибка записана в лог',
            'error': error_message,
            'operation_id': operation_id,
            'timestamp': timezone.now().isoformat(),
        })


class ActiveNewsView(views.APIView):
    """Get active news items for the scrollable banner."""
    
    permission_classes = [permissions.IsAuthenticated]
    
    def get(self, request):
        from django.utils import timezone
        now = timezone.now()
        
        news = News.objects.filter(
            is_active=True,
            published_at__lte=now,
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gte=now)
        ).order_by('-priority', '-published_at')
        
        serializer = NewsSerializer(news, many=True)
        return Response({
            'news': serializer.data,
            'count': news.count(),
        })


class AppVersionCheckView(views.APIView):
    """Check if a newer app version is available."""
    
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = AppVersionCheckSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        platform = serializer.validated_data['platform']
        current_version = serializer.validated_data['current_version']
        build_number = serializer.validated_data.get('build_number', 0)
        
        latest = AppVersion.objects.filter(
            platform=platform,
            is_active=True,
        ).order_by('-build_number').first()
        
        if not latest:
            return Response({'update_available': False})
        
        if build_number >= latest.build_number:
            return Response({'update_available': False})
        
        return Response({
            'update_available': True,
            'version': latest.version,
            'build_number': latest.build_number,
            'is_required': latest.is_required,
            'update_url': latest.update_url,
            'changelog': latest.changelog,
        })

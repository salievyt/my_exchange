"""
URLs for Notifications app.
"""
from django.urls import path
from .views import (
    AppNotificationsView,
    NotificationView,
    NotificationTrackView,
    SendNotificationView,
    ErrorNotificationView,
    AppVersionCheckView,
    ActiveNewsView,
)

urlpatterns = [
    # Main in-app notification endpoint
    path('app-notifications/', AppNotificationsView.as_view(), name='app-notifications'),
    
    # Track notification interaction
    path('app-notifications/<int:notification_id>/track/',
         NotificationTrackView.as_view(), name='notification-track'),
    
    # News endpoint (scrollable banner on main screen)
    path('news/', ActiveNewsView.as_view(), name='active-news'),
    
    # Legacy endpoints
    path('', NotificationView.as_view(), name='notifications'),
    path('send/', SendNotificationView.as_view(), name='send-notification'),
    path('error/', ErrorNotificationView.as_view(), name='error-notification'),
    path('app-version/', AppVersionCheckView.as_view(), name='app-version-check'),
]

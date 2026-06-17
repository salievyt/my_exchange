"""
URLs for Notifications app.
"""
from django.urls import path
from .views import (
    NotificationView,
    SendNotificationView,
    ErrorNotificationView,
    AppVersionCheckView,
)

urlpatterns = [
    path('', NotificationView.as_view(), name='notifications'),
    path('send/', SendNotificationView.as_view(), name='send-notification'),
    path('error/', ErrorNotificationView.as_view(), name='error-notification'),
    path('app-version/', AppVersionCheckView.as_view(), name='app-version-check'),
]

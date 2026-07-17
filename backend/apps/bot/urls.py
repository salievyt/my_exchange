"""
URLs for Telegram Bot app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BotAdminViewSet, BotConfigViewSet

router = DefaultRouter()
router.register(r'bot-admins', BotAdminViewSet, basename='bot-admin')
router.register(r'bot-config', BotConfigViewSet, basename='bot-config')

urlpatterns = [
    path('', include(router.urls)),
]

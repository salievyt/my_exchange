"""
URLs for Currency app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CurrencyViewSet, ExchangeRateViewSet, CurrencyRateHistoryViewSet

router = DefaultRouter()
router.register(r'currencies', CurrencyViewSet, basename='currency')
router.register(r'rates', ExchangeRateViewSet, basename='exchange-rate')
router.register(r'rate-history', CurrencyRateHistoryViewSet, basename='rate-history')

urlpatterns = [
    path('', include(router.urls)),
]

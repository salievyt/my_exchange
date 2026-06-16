"""
URLs for Cash app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CashBalanceViewSet, CashTransactionViewSet, CashRegisterViewSet

router = DefaultRouter()
router.register(r'balances', CashBalanceViewSet, basename='cash-balance')
router.register(r'transactions', CashTransactionViewSet, basename='cash-transaction')
router.register(r'registers', CashRegisterViewSet, basename='cash-register')

urlpatterns = [
    path('', include(router.urls)),
]

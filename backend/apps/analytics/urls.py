"""
URLs for Analytics app.
"""
from django.urls import path
from .views import DashboardStatsView, AnalyticsOperationsView, AnalyticsProfitabilityView, CashierLoadView, ShiftCurrencyStatsView

urlpatterns = [
    path('dashboard/', DashboardStatsView.as_view(), name='dashboard-stats'),
    path('operations/', AnalyticsOperationsView.as_view(), name='analytics-operations'),
    path('profitability/', AnalyticsProfitabilityView.as_view(), name='analytics-profitability'),
    path('cashier-load/', CashierLoadView.as_view(), name='analytics-cashier-load'),
    path('shift-stats/', ShiftCurrencyStatsView.as_view(), name='analytics-shift-stats'),
]

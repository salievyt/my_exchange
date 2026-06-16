"""
URLs for Reports app.
"""
from django.urls import path
from .views import DailyReportView, MonthlyReportView, CashierReportView, ExportView

urlpatterns = [
    path('daily/', DailyReportView.as_view(), name='daily-report'),
    path('monthly/', MonthlyReportView.as_view(), name='monthly-report'),
    path('cashier/<int:cashier_id>/', CashierReportView.as_view(), name='cashier-report'),
    path('cashier/', CashierReportView.as_view(), name='cashier-report-current'),
    path('export/', ExportView.as_view(), name='export-data'),
]

"""
Public API views for landing page data.
No authentication required — returns aggregate/public-facing stats only.
"""
from rest_framework import views
from rest_framework.response import Response
from django.utils import timezone

from apps.currencies.models import Currency, ExchangeRate
from apps.users.models import User
from apps.operations.models import Operation, OperationStatus
from .models import Testimonial, PricingPlan


class LandingStatsView(views.APIView):
    """
    Public endpoint returning aggregate data for the landing page.
    No authentication required — only non-sensitive, public-facing stats.
    """

    authentication_classes = []
    permission_classes = []

    def get(self, request):
        # ── Currencies ──
        active_currencies = Currency.objects.filter(is_active=True).count()

        # ── Users / Exchange points ──
        total_users = User.objects.count()
        admin_users = User.objects.filter(role='admin').count()

        # ── Today's operations ──
        today = timezone.now().date()
        ops_today = Operation.objects.filter(
            created_at__date=today,
            status=OperationStatus.ACTIVE
        ).count()

        # ── Exchange rates (first active buy/sell per currency) ──
        rates = []
        for currency in Currency.objects.filter(is_active=True):
            buy_rate = ExchangeRate.objects.filter(
                currency=currency,
                operation_type='buy',
                is_active=True
            ).first()
            sell_rate = ExchangeRate.objects.filter(
                currency=currency,
                operation_type='sell',
                is_active=True
            ).first()
            if buy_rate or sell_rate:
                rates.append({
                    'code': currency.code,
                    'name': currency.name,
                    'symbol': currency.symbol,
                    'buy': float(buy_rate.rate) if buy_rate else None,
                    'sell': float(sell_rate.rate) if sell_rate else None,
                })
        # ── Pricing Plans ──
        pricing_plans = []
        for p in PricingPlan.objects.filter(is_active=True):
            pricing_plans.append({
                'id': p.id,
                'name': p.name,
                'price': float(p.price),
                'currency': p.currency,
                'description': p.description,
                'features': p.features,
                'is_popular': p.is_popular,
                'button_text': p.button_text,
                'sort_order': p.sort_order,
            })

        # ── Testimonials ──
        testimonials = []
        for t in Testimonial.objects.filter(is_active=True):
            initial = t.name[0].upper() if t.name else '?'
            testimonials.append({
                'id': t.id,
                'name': t.name,
                'role': t.role,
                'content': t.content,
                'rating': t.rating,
                'avatar_color': t.avatar_color,
                'initial': initial,
            })

        return Response({
            'active_currencies': active_currencies,
            'total_users': total_users,
            'admin_users': admin_users,
            'operations_today': ops_today,
            'exchange_rates': rates,
            'pricing_plans': pricing_plans,
            'testimonials': testimonials,
        })

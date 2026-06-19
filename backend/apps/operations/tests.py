"""
Tests for Operation balance validation and cash balance updates.
"""
from decimal import Decimal

from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase, APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.users.models import User, Role
from apps.currencies.models import Currency, ExchangeRate
from apps.cash.models import CashBalance
from apps.operations.models import Operation, OperationType, OperationStatus


class OperationBalanceTests(APITestCase):
    """Test suite for operation balance validation and updates."""

    @classmethod
    def setUpTestData(cls):
        """Set up test data once for all tests."""
        # Create users
        cls.cashier = User.objects.create_user(
            username='cashier1',
            password='testpass123',
            role=Role.CASHIER,
        )
        cls.admin = User.objects.create_user(
            username='admin1',
            password='testpass123',
            role=Role.ADMIN,
        )

        # Create currencies
        cls.kgs = Currency.objects.create(
            code='KGS',
            name='Kyrgyzstani Som',
            symbol='сом',
            is_active=True,
        )
        cls.usd = Currency.objects.create(
            code='USD',
            name='US Dollar',
            symbol='$',
            is_active=True,
        )
        cls.eur = Currency.objects.create(
            code='EUR',
            name='Euro',
            symbol='€',
            is_active=True,
        )

        # Create exchange rates (USD -> KGS, EUR -> KGS)
        cls.usd_rate = ExchangeRate.objects.create(
            currency=cls.usd,
            base_currency=cls.kgs,
            rate=Decimal('85.50'),
            operation_type='buy',
            is_active=True,
            created_by=cls.admin,
        )
        cls.usd_sell_rate = ExchangeRate.objects.create(
            currency=cls.usd,
            base_currency=cls.kgs,
            rate=Decimal('86.00'),
            operation_type='sell',
            is_active=True,
            created_by=cls.admin,
        )
        cls.eur_rate = ExchangeRate.objects.create(
            currency=cls.eur,
            base_currency=cls.kgs,
            rate=Decimal('93.00'),
            operation_type='buy',
            is_active=True,
            created_by=cls.admin,
        )
        cls.eur_sell_rate = ExchangeRate.objects.create(
            currency=cls.eur,
            base_currency=cls.kgs,
            rate=Decimal('94.00'),
            operation_type='sell',
            is_active=True,
            created_by=cls.admin,
        )

        # Create cash balances
        # KGS cash balance: 100,000 som
        CashBalance.objects.create(
            currency=cls.kgs,
            balance=Decimal('100000'),
            reserved=Decimal('0'),
        )
        # USD cash balance: 1,000 dollars
        CashBalance.objects.create(
            currency=cls.usd,
            balance=Decimal('1000'),
            reserved=Decimal('0'),
        )
        # EUR cash balance: 500 euros
        CashBalance.objects.create(
            currency=cls.eur,
            balance=Decimal('500'),
            reserved=Decimal('0'),
        )

    def setUp(self):
        """Set up authenticated client for each test."""
        self.client = APIClient()
        refresh = RefreshToken.for_user(self.cashier)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        self.url = reverse('operation-list')

    # ─── BUY Operation Tests ───────────────────────────────────────

    def test_buy_success_with_sufficient_kgs(self):
        """
        BUY operation should succeed when KGS balance is sufficient.
        Expected: 201 Created, foreign currency balance increases, KGS decreases.
        """
        kgs_before = CashBalance.objects.get(currency=self.kgs).balance
        usd_before = CashBalance.objects.get(currency=self.usd).balance

        response = self.client.post(self.url, {
            'operation_type': 'buy',
            'currency': self.usd.id,
            'amount': 100,  # buy 100 USD
            'rate': 85.50,  # rate = 85.50 KGS per USD
            'client_name': 'Test Client',
        }, format='json')

        # Assert response
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', response.data)

        # Assert balance updates
        usd_after = CashBalance.objects.get(currency=self.usd).balance
        kgs_after = CashBalance.objects.get(currency=self.kgs).balance

        # USD should increase by 100
        self.assertEqual(usd_after, usd_before + Decimal('100'))
        # KGS should decrease by 100 * 85.50 = 8,550
        expected_kgs = kgs_before - Decimal('8550')
        self.assertEqual(kgs_after, expected_kgs)

    def test_buy_fails_when_kgs_insufficient(self):
        """
        BUY operation should fail when KGS balance is insufficient.
        Expected: 400 Bad Request, balances unchanged.
        """
        kgs_before = CashBalance.objects.get(currency=self.kgs).balance
        usd_before = CashBalance.objects.get(currency=self.usd).balance

        # Try to buy USD worth more than available KGS
        # Available KGS: 100,000; trying to buy 2,000 USD at 85.50 = 171,000 KGS needed
        response = self.client.post(self.url, {
            'operation_type': 'buy',
            'currency': self.usd.id,
            'amount': 2000,
            'rate': 85.50,
            'client_name': 'Test Client',
        }, format='json')

        # Assert failure
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('Недостаточно сом', str(response.data['error']))

        # Assert balances unchanged
        usd_after = CashBalance.objects.get(currency=self.usd).balance
        kgs_after = CashBalance.objects.get(currency=self.kgs).balance
        self.assertEqual(usd_after, usd_before)
        self.assertEqual(kgs_after, kgs_before)

    def test_buy_fails_when_kgs_no_balance_record(self):
        """
        BUY operation should fail when there's no KGS cash balance record.
        Expected: 400 Bad Request, balances unchanged.
        """
        usd_before = CashBalance.objects.get(currency=self.usd).balance

        # Delete KGS cash balance record
        CashBalance.objects.filter(currency=self.kgs).delete()

        response = self.client.post(self.url, {
            'operation_type': 'buy',
            'currency': self.usd.id,
            'amount': 100,
            'rate': 85.50,
            'client_name': 'Test Client',
        }, format='json')

        # Assert failure
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

        # Assert balances unchanged
        usd_after = CashBalance.objects.get(currency=self.usd).balance
        self.assertEqual(usd_after, usd_before)

    # ─── SELL Operation Tests ──────────────────────────────────────

    def test_sell_success_with_sufficient_currency(self):
        """
        SELL operation should succeed when foreign currency balance is sufficient.
        Expected: 201 Created, foreign currency decreases, KGS increases.
        """
        kgs_before = CashBalance.objects.get(currency=self.kgs).balance
        usd_before = CashBalance.objects.get(currency=self.usd).balance

        response = self.client.post(self.url, {
            'operation_type': 'sell',
            'currency': self.usd.id,
            'amount': 100,  # sell 100 USD
            'rate': 86.00,   # sell rate = 86.00 KGS per USD
            'client_name': 'Test Client',
        }, format='json')

        # Assert response
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', response.data)

        # Assert balance updates
        usd_after = CashBalance.objects.get(currency=self.usd).balance
        kgs_after = CashBalance.objects.get(currency=self.kgs).balance

        # USD should decrease by 100
        self.assertEqual(usd_after, usd_before - Decimal('100'))
        # KGS should increase by 100 * 86.00 = 8,600
        expected_kgs = kgs_before + Decimal('8600')
        self.assertEqual(kgs_after, expected_kgs)

    def test_sell_fails_when_currency_insufficient(self):
        """
        SELL operation should fail when foreign currency balance is insufficient.
        Expected: 400 Bad Request, balances unchanged.
        """
        kgs_before = CashBalance.objects.get(currency=self.kgs).balance
        eur_before = CashBalance.objects.get(currency=self.eur).balance

        # Try to sell 1000 EUR but only 500 available
        response = self.client.post(self.url, {
            'operation_type': 'sell',
            'currency': self.eur.id,
            'amount': 1000,
            'rate': 94.00,
            'client_name': 'Test Client',
        }, format='json')

        # Assert failure
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('Недостаточно валюты', str(response.data['error']))

        # Assert balances unchanged
        eur_after = CashBalance.objects.get(currency=self.eur).balance
        kgs_after = CashBalance.objects.get(currency=self.kgs).balance
        self.assertEqual(eur_after, eur_before)
        self.assertEqual(kgs_after, kgs_before)

    def test_sell_fails_when_no_currency_balance(self):
        """
        SELL operation should fail when there's no cash balance record for the currency.
        Expected: 400 Bad Request.
        """
        # Delete EUR cash balance
        CashBalance.objects.filter(currency=self.eur).delete()

        response = self.client.post(self.url, {
            'operation_type': 'sell',
            'currency': self.eur.id,
            'amount': 100,
            'rate': 94.00,
            'client_name': 'Test Client',
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    # ─── Balance Precision Tests ───────────────────────────────────

    def test_buy_balance_precision(self):
        """
        BUY operation should handle decimal precision correctly.
        """
        kgs_before = CashBalance.objects.get(currency=self.kgs).balance

        # Buy 250.75 USD at rate 85.55
        response = self.client.post(self.url, {
            'operation_type': 'buy',
            'currency': self.usd.id,
            'amount': 250.75,
            'rate': 85.55,
            'client_name': 'Test',
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        usd_after = CashBalance.objects.get(currency=self.usd).balance
        kgs_after = CashBalance.objects.get(currency=self.kgs).balance

        # USD should be 1000 + 250.75 = 1250.75
        self.assertEqual(usd_after, Decimal('1250.75'))
        # KGS should be 100000 - (250.75 * 85.55) = 100000 - 21451.6625 = 78548.3375
        # But we need to check the operation's total_amount
        operation = Operation.objects.latest('created_at')
        expected_kgs = kgs_before - operation.total_amount
        self.assertEqual(kgs_after, expected_kgs)

    # ─── Authentication Tests ──────────────────────────────────────

    def test_create_requires_authentication(self):
        """
        Unauthenticated requests should be rejected.
        """
        self.client.credentials()  # Remove auth
        response = self.client.post(self.url, {
            'operation_type': 'buy',
            'currency': self.usd.id,
            'amount': 100,
            'rate': 85.50,
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

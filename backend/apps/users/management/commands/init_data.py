"""
Management command to initialize database with default data.
"""
from django.core.management.base import BaseCommand
from django.db import transaction
from apps.users.models import User, Role
from apps.currencies.models import Currency, ExchangeRate
from apps.cash.models import CashBalance


class Command(BaseCommand):
    help = 'Initialize database with default currencies and admin user'

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write('Starting initialization...')

        # Create default currencies
        currencies_data = [
            {'code': 'KGS', 'name': 'Кыргызский сом', 'symbol': 'сом'},
            {'code': 'USD', 'name': 'Доллар США', 'symbol': '$'},
            {'code': 'EUR', 'name': 'Евро', 'symbol': '€'},
            {'code': 'RUB', 'name': 'Российский рубль', 'symbol': '₽'},
            {'code': 'KZT', 'name': 'Казахстанский тенге', 'symbol': '₸'},
            {'code': 'CNY', 'name': 'Китайский юань', 'symbol': '¥'},
        ]

        for curr_data in currencies_data:
            currency, created = Currency.objects.get_or_create(
                code=curr_data['code'],
                defaults=curr_data
            )
            if created:
                self.stdout.write(f'Created currency: {currency.code}')
            
            # Create cash balance for currency
            CashBalance.objects.get_or_create(currency=currency)

        # Create default exchange rates (example rates)
        rates_data = [
            {'currency': 'USD', 'buy': 89.50, 'sell': 90.50},
            {'currency': 'EUR', 'buy': 97.00, 'sell': 98.50},
            {'currency': 'RUB', 'buy': 0.95, 'sell': 1.05},
            {'currency': 'KZT', 'buy': 0.19, 'sell': 0.22},
            {'currency': 'CNY', 'buy': 12.30, 'sell': 12.80},
        ]

        for rate_data in rates_data:
            currency = Currency.objects.get(code=rate_data['currency'])
            
            # Create buy rate
            ExchangeRate.objects.get_or_create(
                currency=currency,
                operation_type='buy',
                defaults={
                    'rate': rate_data['buy'],
                    'is_active': True
                }
            )
            
            # Create sell rate
            ExchangeRate.objects.get_or_create(
                currency=currency,
                operation_type='sell',
                defaults={
                    'rate': rate_data['sell'],
                    'is_active': True
                }
            )
            
            self.stdout.write(f'Created rates for {currency.code}')

        # Create admin user
        admin, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'email': 'admin@myexchange.kg',
                'first_name': 'Admin',
                'last_name': 'User',
                'role': Role.ADMIN,
                'is_staff': True,
                'is_superuser': True,
            }
        )
        
        if created:
            admin.set_password('admin123')
            admin.save()
            self.stdout.write(self.style.SUCCESS('Created admin user (username: admin, password: admin123)'))
        else:
            self.stdout.write('Admin user already exists')

        # Create sample cashier
        cashier, created = User.objects.get_or_create(
            username='cashier1',
            defaults={
                'email': 'cashier1@myexchange.kg',
                'first_name': 'Иван',
                'last_name': 'Петров',
                'role': Role.CASHIER,
            }
        )
        
        if created:
            cashier.set_password('cashier123')
            cashier.save()
            self.stdout.write(self.style.SUCCESS('Created cashier user (username: cashier1, password: cashier123)'))
        else:
            self.stdout.write('Cashier user already exists')

        self.stdout.write(self.style.SUCCESS('Initialization completed successfully!'))
        self.stdout.write(self.style.WARNING('IMPORTANT: Change default passwords in production!'))

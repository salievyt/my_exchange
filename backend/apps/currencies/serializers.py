"""
Serializers for Currency app.
"""
from rest_framework import serializers
from .models import Currency, ExchangeRate, CurrencyRateHistory


class CurrencySerializer(serializers.ModelSerializer):
    """Serializer for currency."""
    
    buy_rate = serializers.SerializerMethodField()
    sell_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = Currency
        fields = [
            'id', 'code', 'name', 'symbol', 'is_active',
            'buy_rate', 'sell_rate', 'created_at', 'updated_at'
        ]
    
    def get_buy_rate(self, obj):
        active_rate = obj.exchange_rates.filter(
            operation_type='buy',
            is_active=True
        ).first()
        return active_rate.rate if active_rate else None
    
    def get_sell_rate(self, obj):
        active_rate = obj.exchange_rates.filter(
            operation_type='sell',
            is_active=True
        ).first()
        return active_rate.rate if active_rate else None


class CurrencyCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating currency."""
    
    class Meta:
        model = Currency
        fields = ['code', 'name', 'symbol', 'is_active']


class ExchangeRateSerializer(serializers.ModelSerializer):
    """Serializer for exchange rate."""
    
    currency_code = serializers.CharField(source='currency.code', read_only=True)
    currency_name = serializers.CharField(source='currency.name', read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = ExchangeRate
        fields = [
            'id', 'currency', 'currency_code', 'currency_name',
            'base_currency', 'rate', 'operation_type', 'is_active',
            'created_by', 'created_by_username', 'created_at',
            'valid_from', 'valid_until'
        ]
        read_only_fields = ['created_at', 'valid_from', 'valid_until']


class ExchangeRateCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating exchange rate."""
    
    class Meta:
        model = ExchangeRate
        fields = [
            'currency', 'rate', 'operation_type', 'is_active'
        ]
    
    def validate_rate(self, value):
        if value <= 0:
            raise serializers.ValidationError("Курс должен быть положительным числом")
        return value


class CurrencyRateHistorySerializer(serializers.ModelSerializer):
    """Serializer for rate history."""
    
    currency_code = serializers.CharField(source='currency.code', read_only=True)
    changed_by_username = serializers.CharField(source='changed_by.username', read_only=True)
    
    class Meta:
        model = CurrencyRateHistory
        fields = [
            'id', 'currency', 'currency_code', 'old_rate', 'new_rate',
            'operation_type', 'changed_by', 'changed_by_username',
            'changed_at', 'comment'
        ]

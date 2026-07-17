"""
Serializers for Cash app.
"""
from rest_framework import serializers
from .models import CashBalance, CashTransaction, CashRegister, CashTransactionType


class CashBalanceSerializer(serializers.ModelSerializer):
    """Serializer for cash balance."""
    
    currency_code = serializers.CharField(source='currency.code', read_only=True)
    currency_name = serializers.CharField(source='currency.name', read_only=True)
    currency_symbol = serializers.CharField(source='currency.symbol', read_only=True)
    available_balance = serializers.ReadOnlyField()
    balance_from_operations = serializers.SerializerMethodField()
    
    class Meta:
        model = CashBalance
        fields = [
            'id', 'currency', 'currency_code', 'currency_name', 'currency_symbol',
            'balance', 'balance_from_operations', 'reserved', 'available_balance', 'last_updated'
        ]
        read_only_fields = ['last_updated']
    
    def get_balance_from_operations(self, obj):
        """Get balance considering only buy/sell operations (excl cash transactions).
        Reads from serializer context 'ops_balance' dict, falls back to actual balance.
        """
        ops_balance = self.context.get('ops_balance', {})
        code = obj.currency.code
        if code in ops_balance:
            return ops_balance[code]
        return float(obj.balance)


class CashTransactionSerializer(serializers.ModelSerializer):
    """Serializer for cash transaction."""
    
    transaction_type_display = serializers.CharField(source='get_transaction_type_display', read_only=True)
    currency_code = serializers.CharField(source='currency.code', read_only=True)
    cashier_username = serializers.CharField(source='cashier.username', read_only=True)
    cashier_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CashTransaction
        fields = [
            'id', 'transaction_type', 'transaction_type_display', 'currency',
            'currency_code', 'amount', 'balance_before', 'balance_after',
            'cashier', 'cashier_username', 'cashier_name', 'comment', 'created_at'
        ]
        read_only_fields = ['balance_before', 'balance_after', 'created_at']
    
    def get_cashier_name(self, obj):
        return f"{obj.cashier.first_name} {obj.cashier.last_name}"


class CashTransactionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating cash transactions."""
    
    class Meta:
        model = CashTransaction
        fields = [
            'transaction_type', 'currency', 'amount', 'comment'
        ]
    
    def validate(self, attrs):
        amount = attrs.get('amount')
        transaction_type = attrs.get('transaction_type')
        currency = attrs.get('currency')
        
        if amount <= 0:
            raise serializers.ValidationError({"amount": "Сумма должна быть положительной"})
        
        # Check balance for withdrawals
        if transaction_type in [CashTransactionType.WITHDRAWAL, CashTransactionType.INKASSATION]:
            cash_balance = CashBalance.objects.filter(currency=currency).first()
            if not cash_balance or cash_balance.balance < amount:
                raise serializers.ValidationError({
                    "amount": f"Недостаточно средств. Доступно: {cash_balance.balance if cash_balance else 0}"
                })
        
        return attrs


class CashRegisterSerializer(serializers.ModelSerializer):
    """Serializer for cash register."""
    
    cashier_username = serializers.CharField(source='cashier.username', read_only=True)
    cashier_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CashRegister
        fields = [
            'id', 'cashier', 'cashier_username', 'cashier_name',
            'opened_at', 'closed_at', 'is_open', 'opening_balance',
            'closing_balance', 'comment'
        ]
        read_only_fields = ['opened_at', 'closed_at', 'is_open']
    
    def get_cashier_name(self, obj):
        return f"{obj.cashier.first_name} {obj.cashier.last_name}"


class CashRegisterCreateSerializer(serializers.ModelSerializer):
    """Serializer for opening cash register."""
    
    class Meta:
        model = CashRegister
        fields = ['comment']

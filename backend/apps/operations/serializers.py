"""
Serializers for Operation app.
"""
from rest_framework import serializers
from django.utils import timezone
from .models import Operation, OperationEditHistory, OperationCancellation
from apps.currencies.models import ExchangeRate


class OperationSerializer(serializers.ModelSerializer):
    """Serializer for operation."""
    
    operation_type_display = serializers.CharField(source='get_operation_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    currency_code = serializers.CharField(source='currency.code', read_only=True)
    currency_name = serializers.CharField(source='currency.name', read_only=True)
    cashier_username = serializers.CharField(source='cashier.username', read_only=True)
    cashier_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Operation
        fields = [
            'id', 'operation_number', 'operation_type', 'operation_type_display',
            'status', 'status_display', 'client_name', 'client_company',
            'currency', 'currency_code', 'currency_name', 'rate',
            'amount', 'total_amount', 'cashier', 'cashier_username',
            'cashier_name', 'comment', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'operation_number', 'total_amount', 'status',
            'created_at', 'updated_at'
        ]
    
    def get_cashier_name(self, obj):
        return f"{obj.cashier.first_name} {obj.cashier.last_name}"


class OperationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating operations."""
    
    class Meta:
        model = Operation
        fields = [
            'operation_type', 'client_name', 'client_company',
            'currency', 'rate', 'amount', 'comment'
        ]
    
    def validate(self, attrs):
        # Validate rate is positive
        if attrs.get('rate', 0) <= 0:
            raise serializers.ValidationError({"rate": "Курс должен быть положительным"})
        
        # Validate amount is positive
        if attrs.get('amount', 0) <= 0:
            raise serializers.ValidationError({"amount": "Сумма должна быть положительной"})
        
        # Validate rate matches current exchange rate (with small tolerance)
        currency = attrs.get('currency')
        operation_type = attrs.get('operation_type')
        rate = attrs.get('rate')
        
        if currency and operation_type:
            current_rate = ExchangeRate.objects.filter(
                currency=currency,
                operation_type=operation_type,
                is_active=True
            ).first()
            
            if current_rate:
                tolerance = 0.01  # 1% tolerance
                if abs(float(rate) - float(current_rate.rate)) / float(current_rate.rate) > tolerance:
                    raise serializers.ValidationError({
                        "rate": f"Курс отличается от текущего более чем на 1%. Текущий: {current_rate.rate}"
                    })
        
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        
        # Calculate total amount
        amount = validated_data['amount']
        rate = validated_data['rate']
        total_amount = amount * rate
        
        # Create operation
        operation = Operation.objects.create(
            cashier=request.user,
            total_amount=total_amount,
            **validated_data
        )
        
        return operation


class OperationUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating operations."""
    
    class Meta:
        model = Operation
        fields = ['amount', 'rate', 'comment', 'client_name', 'client_company']
    
    def validate(self, attrs):
        # Validate rate and amount if provided
        if 'rate' in attrs and attrs['rate'] <= 0:
            raise serializers.ValidationError({"rate": "Курс должен быть положительным"})
        if 'amount' in attrs and attrs['amount'] <= 0:
            raise serializers.ValidationError({"amount": "Сумма должна быть положительной"})
        return attrs


class OperationEditHistorySerializer(serializers.ModelSerializer):
    """Serializer for operation edit history."""
    
    edited_by_username = serializers.CharField(source='edited_by.username', read_only=True)
    edited_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = OperationEditHistory
        fields = [
            'id', 'operation', 'edited_by', 'edited_by_username',
            'edited_by_name', 'edited_at', 'field_changed',
            'old_value', 'new_value', 'comment'
        ]
    
    def get_edited_by_name(self, obj):
        if obj.edited_by:
            return f"{obj.edited_by.first_name} {obj.edited_by.last_name}"
        return None


class OperationCancellationSerializer(serializers.ModelSerializer):
    """Serializer for operation cancellation."""
    
    cancelled_by_username = serializers.CharField(source='cancelled_by.username', read_only=True)
    cancelled_by_name = serializers.SerializerMethodField()
    
    class Meta:
        model = OperationCancellation
        fields = [
            'id', 'operation', 'cancelled_by', 'cancelled_by_username',
            'cancelled_by_name', 'cancelled_at', 'cancellation_type',
            'cancel_amount', 'reason'
        ]
        read_only_fields = ['cancelled_at']

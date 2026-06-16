"""
Serializers for User app.
"""
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from .models import Role, LoginHistory

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Serializer for user data."""
    
    role_display = serializers.CharField(source='get_role_display', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name',
            'role', 'role_display', 'phone', 'is_two_factor_enabled',
            'created_at', 'updated_at', 'is_active'
        ]
        read_only_fields = ['created_at', 'updated_at', 'is_two_factor_enabled']


class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new users."""
    
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirm = serializers.CharField(write_only=True, min_length=8)
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password_confirm',
            'first_name', 'last_name', 'role', 'phone'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Пароли не совпадают"})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating users."""
    
    class Meta:
        model = User
        fields = [
            'email', 'first_name', 'last_name', 'role', 'phone', 'is_active'
        ]


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for password change."""
    
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, min_length=8)
    new_password_confirm = serializers.CharField(required=True, min_length=8)
    
    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password": "Пароли не совпадают"})
        return attrs


class LoginHistorySerializer(serializers.ModelSerializer):
    """Serializer for login history."""
    
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = LoginHistory
        fields = [
            'id', 'user', 'username', 'login_time', 'logout_time',
            'ip_address', 'user_agent', 'is_active'
        ]


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom token serializer with user data."""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Add user info to response
        data['user'] = UserSerializer(self.user).data
        
        return data

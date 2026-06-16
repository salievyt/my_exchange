"""
Serializers for Logs app.
"""
from rest_framework import serializers
from .models import AuditLog, ActionType


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit log."""
    
    action_display = serializers.CharField(source='get_action_display', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = AuditLog
        fields = [
            'id', 'user', 'username', 'action', 'action_display',
            'model_name', 'object_id', 'ip_address', 'user_agent',
            'details', 'timestamp'
        ]
        read_only_fields = fields

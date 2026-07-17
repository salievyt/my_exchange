"""
Serializers for Registration Requests app.
"""
from django.utils import timezone
from rest_framework import serializers
from .models import RegistrationRequest, RequestStatus, Testimonial, PricingPlan
from .fields import KgPhoneField


class PricingPlanSerializer(serializers.ModelSerializer):
    """
    Serializer for PricingPlan — public-facing, no auth required.
    """

    class Meta:
        model = PricingPlan
        fields = [
            'id', 'name', 'price', 'currency', 'description',
            'features', 'is_popular', 'sort_order', 'button_text'
        ]


class TestimonialSerializer(serializers.ModelSerializer):
    """
    Serializer for Testimonial — public-facing, no auth required.
    """
    initial = serializers.SerializerMethodField()

    class Meta:
        model = Testimonial
        fields = ['id', 'name', 'role', 'content', 'rating', 'avatar_color', 'initial', 'sort_order']

    def get_initial(self, obj):
        """Return first letter of the name for avatar."""
        return obj.name[0].upper() if obj.name else '?'


class RegistrationRequestSerializer(serializers.ModelSerializer):
    """
    Serializer for RegistrationRequest - used for public submission.
    """
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    city_display = serializers.SerializerMethodField()

    class Meta:
        model = RegistrationRequest
        fields = [
            'id', 'name', 'phone', 'city', 'city_display', 'email', 'organization_name',
            'comment', 'status', 'status_display', 'created_at', 'updated_at'
        ]
        read_only_fields = ['status', 'status_display', 'city_display', 'created_at', 'updated_at']

    def get_city_display(self, obj):
        return obj.get_city_display() if obj.city else ''


class RegistrationRequestCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating registration requests (public endpoint).
    """

    phone = KgPhoneField()

    class Meta:
        model = RegistrationRequest
        fields = ['name', 'phone', 'city', 'email', 'organization_name', 'comment']

    def validate(self, attrs):
        """
        Check for duplicate requests from the same phone number today.
        """
        phone = attrs.get('phone')
        if phone:
            today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
            duplicate = RegistrationRequest.objects.filter(
                phone=phone,
                created_at__gte=today_start
            ).exists()
            if duplicate:
                raise serializers.ValidationError(
                    {"phone": "Заявка с этого номера уже отправлена сегодня. Мы свяжемся с вами в ближайшее время."}
                )
        return attrs

    def create(self, validated_data):
        request = RegistrationRequest.objects.create(**validated_data)
        return request


class RegistrationRequestAdminSerializer(serializers.ModelSerializer):
    """
    Serializer for admin management of registration requests.
    """
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = RegistrationRequest
        fields = '__all__'
        read_only_fields = ['created_at', 'updated_at']

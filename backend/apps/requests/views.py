"""
Views for Registration Requests app.
"""
from rest_framework import viewsets, permissions, status, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.throttling import AnonRateThrottle
from .models import RegistrationRequest, RequestStatus
from .serializers import (
    RegistrationRequestSerializer,
    RegistrationRequestCreateSerializer,
)


class RegistrationRateThrottle(AnonRateThrottle):
    """
    Limits anonymous requests to /api/requests/ to 5 per minute per real client IP.
    Uses Redis cache backend to track request counts.
    Takes IP from X-Forwarded-For header (set by nginx) to correctly identify
    clients behind the reverse proxy.
    """
    rate = "5/minute"

    def get_ident(self, request):
        """Extract real client IP from X-Forwarded-For, set by nginx."""
        forwarded = request.META.get('HTTP_X_FORWARDED_FOR', '')
        if forwarded:
            return forwarded.split(',')[0].strip()
        return super().get_ident(request)


class IsAdminUser(permissions.BasePermission):
    """Permission for admin users only."""
    def has_permission(self, request, view):
        return request.user and request.user.is_staff


class RegistrationRequestViewSet(mixins.CreateModelMixin,
                                  mixins.ListModelMixin,
                                  mixins.RetrieveModelMixin,
                                  mixins.UpdateModelMixin,
                                  viewsets.GenericViewSet):
    """
    ViewSet for RegistrationRequest.
    - Public: anyone can create a request
    - Authenticated staff: can list, retrieve, update requests
    """
    queryset = RegistrationRequest.objects.all()
    search_fields = ['name', 'phone', 'email', 'organization_name']

    def get_serializer_class(self):
        if self.action == 'create':
            return RegistrationRequestCreateSerializer
        return RegistrationRequestSerializer

    def get_permissions(self):
        if self.action == 'create':
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated(), IsAdminUser()]

    def get_throttles(self):
        """Apply rate limiting only to the create action."""
        if self.action == 'create':
            return [RegistrationRateThrottle()]
        return []

    def throttled(self, request, wait):
        """Return Russian error message when rate limit exceeded."""
        from rest_framework.exceptions import Throttled
        raise Throttled(detail="Слишком много запросов. Попробуйте через минуту.")

    def get_queryset(self):
        queryset = RegistrationRequest.objects.all()

        # Filter by status
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)

        return queryset

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # Fire notification to Telegram bot (signal-based)
        from .signals import request_created
        request_created.send(sender=self.__class__, instance=serializer.instance)

        return Response(
            {
                "message": "Ваша заявка принята! Мы свяжемся с вами в ближайшее время.",
                "data": RegistrationRequestSerializer(serializer.instance).data
            },
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        """Approve a registration request."""
        instance = self.get_object()
        instance.status = RequestStatus.APPROVED
        instance.save()
        return Response(RegistrationRequestSerializer(instance).data)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a registration request."""
        instance = self.get_object()
        instance.status = RequestStatus.REJECTED
        instance.save()
        return Response(RegistrationRequestSerializer(instance).data)

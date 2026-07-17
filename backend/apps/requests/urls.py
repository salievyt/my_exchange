"""
URLs for Registration Requests app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RegistrationRequestViewSet
from .views_api_landing import LandingStatsView

router = DefaultRouter()
router.register(r'requests', RegistrationRequestViewSet, basename='registration-request')

urlpatterns = [
    path('', include(router.urls)),
    path('landing/', LandingStatsView.as_view(), name='landing-stats'),
]

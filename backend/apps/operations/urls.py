"""
URLs for Operation app.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OperationViewSet

router = DefaultRouter()
router.register(r'operations', OperationViewSet, basename='operation')

urlpatterns = [
    path('', include(router.urls)),
]

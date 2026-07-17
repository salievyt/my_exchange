"""
URLs for landing page.
"""
from django.urls import path
from .views_landing import landing_page

urlpatterns = [
    path('', landing_page, name='landing-page'),
]

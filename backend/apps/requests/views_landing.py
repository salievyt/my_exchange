"""
Landing page view for My Exchange.
"""
from django.shortcuts import render


def landing_page(request):
    """Render the landing page with registration form."""
    return render(request, 'landing.html')

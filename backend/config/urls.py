"""
URL configuration for My Exchange project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from apps.health.views import healthcheck

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Healthcheck (no auth — used by Docker and load balancers)
    path('api/health/', healthcheck, name='healthcheck'),

    # API Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    
    # API endpoints
    path('api/auth/', include('apps.users.urls')),
    path('api/currencies/', include('apps.currencies.urls')),
    path('api/operations/', include('apps.operations.urls')),
    path('api/cash/', include('apps.cash.urls')),
    path('api/reports/', include('apps.reports.urls')),
    path('api/logs/', include('apps.logs.urls')),
    path('api/analytics/', include('apps.analytics.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/', include('apps.requests.urls')),
    path('api/', include('apps.bot.urls')),
    
    # Telegram bot webhook
    path('webhook/telegram/', include('apps.bot.urls_webhook')),
    
    # Landing page
    path('', include('apps.requests.urls_landing')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

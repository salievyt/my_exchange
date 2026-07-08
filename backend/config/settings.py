"""
Django settings for My Exchange project.
"""
import os
from pathlib import Path
from decouple import config

# Build paths
BASE_DIR = Path(__file__).resolve().parent.parent

# Security
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-this-in-production')
DEBUG = config('DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1').split(',')

# Application definition
INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'drf_spectacular',
    'django_filters',
    
    # Local apps
    'apps.users',
    'apps.currencies',
    'apps.operations',
    'apps.cash',
    'apps.reports',
    'apps.logs',
    'apps.analytics',
    'apps.notifications',
    'apps.requests',
    'apps.bot',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'apps.logs.middleware.AuditLogMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='my_exchange'),
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='postgres'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}

# Redis for caching and channels
REDIS_HOST = config('REDIS_HOST', default='localhost')
REDIS_PORT = config('REDIS_PORT', default='6379')

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': f'redis://{REDIS_HOST}:{REDIS_PORT}/1',
    }
}

# Channel layers for notifications
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [(REDIS_HOST, int(REDIS_PORT))],
        },
    },
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'ru-ru'
TIME_ZONE = 'Asia/Bishkek'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Jazzmin — Django Admin Theme
JAZZMIN_SETTINGS = {
    # Title and branding
    'site_title': 'My Exchange',
    'site_header': 'My Exchange',
    'site_brand': 'My Exchange',
    'welcome_sign': 'Добро пожаловать в My Exchange',
    'copyright': 'My Exchange © 2026',
    
    # Logo (uses static files)
    'site_logo': None,
    'login_logo': None,
    'login_logo_dark': None,
    
    # Icons
    'icons': {
        'auth.User': 'fas fa-user',
        'auth.Group': 'fas fa-users-cog',
        'users.User': 'fas fa-user',
        'users.LoginHistory': 'fas fa-sign-in-alt',
        'currencies.Currency': 'fas fa-money-bill-wave',
        'currencies.ExchangeRate': 'fas fa-chart-line',
        'currencies.CurrencyRateHistory': 'fas fa-history',
        'operations.Operation': 'fas fa-exchange-alt',
        'operations.OperationEditHistory': 'fas fa-pen',
        'operations.OperationCancellation': 'fas fa-ban',
        'cash.CashBalance': 'fas fa-coins',
        'cash.CashTransaction': 'fas fa-hand-holding-usd',
        'cash.CashRegister': 'fas fa-cash-register',
        'logs.AuditLog': 'fas fa-clipboard-list',
    },
    
    # Related modal
    'related_modal_active': True,
    
    # UI customizer
    'show_ui_builder': False,
    
    # Top menu
    'custom_links': None,
    
    # Dashboard widgets
    'dashboard_widgets': [
        {
            'name': 'request_stats',
            'class': 'apps.requests.admin.RequestDashboardWidget',
            'width': 'col-lg-6',
        },
    ],
    
    # Order of apps in menu
    'order_with_respect_to': [
        'users',
        'currencies',
        'operations',
        'cash',
        'logs',
        'notifications',
        'reports',
        'analytics',
        'auth',
    ],
}

JAZZMIN_UI_TWEAKS = {
    'theme': 'flatly',
    'dark_mode_theme': None,
    'brand_colour': 'primary',
    'accent': 'primary',
    'navbar': 'navbar navbar-expand-lg navbar-dark bg-primary',
    'sidebar': 'sidebar-dark-primary',
    'button_classes': {
        'primary': 'btn btn-primary',
        'secondary': 'btn btn-secondary',
        'info': 'btn btn-info',
        'warning': 'btn btn-warning',
        'danger': 'btn btn-danger',
        'success': 'btn btn-success',
    },
    'actions_sticky_top': True,
}

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom user model
AUTH_USER_MODEL = 'users.User'

# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_FILTER_BACKENDS': [
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
        'django_filters.rest_framework.DjangoFilterBackend',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

# JWT Settings
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=8),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# CORS
CORS_ALLOWED_ORIGINS = config(
    'CORS_ALLOWED_ORIGINS',
    default='http://localhost:3000,http://127.0.0.1:3000,https://dev.phantom-ink.online'
).split(',')

CORS_ALLOW_CREDENTIALS = True

# CSRF
CSRF_TRUSTED_ORIGINS = config(
    'CSRF_TRUSTED_ORIGINS',
    default='http://localhost:3000,http://127.0.0.1:3000,https://dev.phantom-ink.online'
).split(',')

# HTTPS / SSL — enforced by nginx, Django just needs to know it's behind HTTPS
SECURE_SSL_REDIRECT = False  # nginx handles HTTP→HTTPS redirect

# Trust X-Forwarded-Proto when behind a reverse proxy (nginx, Caddy, etc.)
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# HSTS — force HTTPS for 1 year (nginx also sets this)
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = config('SECURE_HSTS_PRELOAD', default=False, cast=bool)

# Secure cookies — use env vars so they can be disabled when not behind HTTPS
CSRF_COOKIE_SECURE = config('CSRF_COOKIE_SECURE', default=True, cast=bool)
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = 'Lax'
SESSION_COOKIE_SECURE = config('SESSION_COOKIE_SECURE', default=True, cast=bool)
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'

# Security Headers
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = 'strict-origin-when-cross-origin'

# Backup settings
BACKUP_DIR = BASE_DIR / 'backups'
BACKUP_KEEP_DAYS = config('BACKUP_KEEP_DAYS', default=30, cast=int)

# Telegram Bot settings
BOT_TOKEN = config('BOT_TOKEN', default='')
BOT_WEBHOOK_URL = config('BOT_WEBHOOK_URL', default='')

# Notification settings
NOTIFY_LOW_CASH_THRESHOLD = config('NOTIFY_LOW_CASH_THRESHOLD', default=1000, cast=float)

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'django.log',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}

# Create logs directory
os.makedirs(BASE_DIR / 'logs', exist_ok=True)

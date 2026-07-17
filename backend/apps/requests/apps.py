"""
App configuration for Registration Requests app.
"""
from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class RequestsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.requests'
    verbose_name = _('Заявки на регистрацию')

    def ready(self):
        import apps.requests.receivers  # noqa

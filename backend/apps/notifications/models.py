"""
Models for Notifications app.
In-App Notification & Update Center system.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _


class News(models.Model):
    """News items displayed as scrollable banner on the main screen."""

    title = models.CharField(
        max_length=255,
        verbose_name=_('Заголовок'),
    )
    summary = models.TextField(
        blank=True,
        verbose_name=_('Краткое описание'),
        help_text=_('Отображается под заголовком в баннере'),
    )
    body = models.TextField(
        blank=True,
        verbose_name=_('Полный текст'),
        help_text=_('Открывается при нажатии на баннер'),
    )
    image_url = models.URLField(
        blank=True,
        verbose_name=_('URL изображения'),
    )
    link_url = models.URLField(
        blank=True,
        verbose_name=_('Ссылка'),
        help_text=_('URL для кнопки "Подробнее"'),
    )
    link_text = models.CharField(
        max_length=100,
        blank=True,
        default='Подробнее',
        verbose_name=_('Текст кнопки'),
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активно'),
    )
    priority = models.IntegerField(
        default=0,
        verbose_name=_('Приоритет'),
        help_text=_('Чем выше число, тем левее в карусели'),
    )
    published_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата публикации'),
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_('Дата окончания'),
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания'),
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления'),
    )

    class Meta:
        verbose_name = _('Новость')
        verbose_name_plural = _('Новости')
        ordering = ['-priority', '-published_at']

    def __str__(self):
        return self.title


class AppVersion(models.Model):
    """Track latest app version for update notifications."""

    PLATFORM_CHOICES = [
        ('android', 'Android'),
        ('ios', 'iOS'),
    ]

    platform = models.CharField(
        max_length=20,
        choices=PLATFORM_CHOICES,
        verbose_name=_('Платформа'),
    )
    version = models.CharField(
        max_length=20,
        verbose_name=_('Версия'),
        help_text=_('Например: 1.1.0'),
    )
    build_number = models.IntegerField(
        default=1,
        verbose_name=_('Номер сборки'),
    )
    is_required = models.BooleanField(
        default=False,
        verbose_name=_('Обязательное обновление'),
    )
    update_url = models.URLField(
        blank=True,
        verbose_name=_('Ссылка на обновление'),
    )
    changelog = models.TextField(
        blank=True,
        verbose_name=_('Список изменений'),
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активно'),
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания'),
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления'),
    )

    class Meta:
        verbose_name = _('Версия приложения')
        verbose_name_plural = _('Версии приложений')
        ordering = ['-created_at']
        unique_together = [['platform', 'build_number']]

    def __str__(self):
        return f"{self.get_platform_display()} v{self.version}"


class NotificationType(models.TextChoices):
    """Types of in-app notifications."""
    UPDATE = 'update', _('Обновление приложения')
    NEWS = 'news', _('Новость')
    NEW_FEATURE = 'new_feature', _('Новая функция')
    MAINTENANCE = 'maintenance', _('Технические работы')
    INFO = 'info', _('Информационное сообщение')
    BANNER = 'banner', _('Баннер')


class DisplayFormat(models.TextChoices):
    """How the notification is displayed."""
    FULL_SCREEN = 'full_screen', _('Полноэкранный')
    MODAL = 'modal', _('Модальное окно')
    BOTTOM_SHEET = 'bottom_sheet', _('Нижняя карточка')
    BANNER = 'banner', _('Баннер')
    CARD = 'card', _('Карточка')


class NotificationStatus(models.TextChoices):
    """Publication status of a notification."""
    DRAFT = 'draft', _('Черновик')
    PUBLISHED = 'published', _('Опубликовано')
    ARCHIVED = 'archived', _('Архив')


class Platform(models.TextChoices):
    """Target platform for notifications."""
    ANDROID = 'android', 'Android'
    IOS = 'ios', 'iOS'
    WEB = 'web', 'Web'
    DESKTOP = 'desktop', 'Desktop'
    ALL = 'all', 'Все'


class Notification(models.Model):
    """In-app notification model for the Update Center."""

    title = models.CharField(
        max_length=255,
        verbose_name=_('Заголовок'),
    )
    description = models.TextField(
        blank=True,
        verbose_name=_('Описание'),
    )

    # Type and display
    notification_type = models.CharField(
        max_length=30,
        choices=NotificationType.choices,
        default=NotificationType.INFO,
        verbose_name=_('Тип уведомления'),
    )
    display_format = models.CharField(
        max_length=30,
        choices=DisplayFormat.choices,
        default=DisplayFormat.MODAL,
        verbose_name=_('Формат отображения'),
    )

    # Version info (for update-type notifications)
    app_version = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_('Версия приложения'),
        help_text=_('Версия, к которой относится уведомление (например: 1.4.0)'),
    )
    min_version = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_('Минимальная версия'),
        help_text=_('Минимально поддерживаемая версия'),
    )
    latest_version = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_('Последняя версия'),
        help_text=_('Последняя доступная версия'),
    )
    force_update = models.BooleanField(
        default=False,
        verbose_name=_('Обязательное обновление'),
    )

    # Media and action
    image_url = models.URLField(
        blank=True,
        verbose_name=_('URL изображения'),
    )
    button_url = models.URLField(
        blank=True,
        verbose_name=_('URL кнопки'),
    )
    button_text = models.CharField(
        max_length=100,
        blank=True,
        verbose_name=_('Текст кнопки'),
    )

    # Changelog items (stored as JSON array of strings)
    changelog = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_('Список изменений'),
        help_text=_('Каждый пункт — отдельная строка'),
    )

    # Publication
    publish_at = models.DateTimeField(
        verbose_name=_('Дата публикации'),
    )
    expires_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_('Дата окончания действия'),
    )
    status = models.CharField(
        max_length=20,
        choices=NotificationStatus.choices,
        default=NotificationStatus.DRAFT,
        verbose_name=_('Статус публикации'),
    )

    # Targeting
    platform = models.CharField(
        max_length=20,
        choices=Platform.choices,
        default=Platform.ALL,
        verbose_name=_('Платформа'),
    )
    target_audience = models.CharField(
        max_length=100,
        blank=True,
        verbose_name=_('Целевая аудитория'),
        help_text=_('Роль пользователя или пусто для всех'),
    )
    priority = models.IntegerField(
        default=0,
        verbose_name=_('Приоритет'),
        help_text=_('Чем выше число, тем выше приоритет'),
    )

    # Statistics
    view_count = models.IntegerField(
        default=0,
        editable=False,
        verbose_name=_('Просмотры'),
    )
    click_count = models.IntegerField(
        default=0,
        editable=False,
        verbose_name=_('Переходы по кнопке'),
    )

    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания'),
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления'),
    )

    class Meta:
        verbose_name = _('Уведомление')
        verbose_name_plural = _('Уведомления')
        ordering = ['-priority', '-publish_at']
        indexes = [
            models.Index(fields=['status', 'publish_at']),
            models.Index(fields=['notification_type']),
            models.Index(fields=['priority']),
        ]

    def __str__(self):
        return f"[{self.get_notification_type_display()}] {self.title}"

    def is_active(self):
        """Check if notification is currently active."""
        from django.utils import timezone
        now = timezone.now()
        if self.status != NotificationStatus.PUBLISHED:
            return False
        if self.publish_at > now:
            return False
        if self.expires_at and self.expires_at < now:
            return False
        return True

    def increment_view(self):
        self.view_count += 1
        self.save(update_fields=['view_count'])

    def increment_click(self):
        self.click_count += 1
        self.save(update_fields=['click_count'])

"""
Models for Registration Requests app.
"""
from django.db import models
from django.utils.translation import gettext_lazy as _


class RequestStatus(models.TextChoices):
    PENDING = 'pending', _('На рассмотрении')
    APPROVED = 'approved', _('Одобрена')
    REJECTED = 'rejected', _('Отклонена')


class PricingPlan(models.Model):
    """
    Model for pricing plans displayed on the landing page.
    """
    name = models.CharField(
        max_length=255,
        verbose_name=_('Название тарифа')
    )
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name=_('Цена')
    )
    currency = models.CharField(
        max_length=50,
        default='сом/мес',
        verbose_name=_('Валюта / период')
    )
    description = models.CharField(
        max_length=500,
        blank=True,
        verbose_name=_('Описание')
    )
    features = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_('Возможности (JSON-список)')
    )
    is_popular = models.BooleanField(
        default=False,
        verbose_name=_('Популярный тариф')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активен')
    )
    sort_order = models.PositiveIntegerField(
        default=0,
        verbose_name=_('Порядок сортировки')
    )
    button_text = models.CharField(
        max_length=100,
        default='Начать',
        verbose_name=_('Текст кнопки')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания')
    )

    class Meta:
        verbose_name = _('Тариф')
        verbose_name_plural = _('Тарифы')
        ordering = ['sort_order', 'price']

    def __str__(self):
        return f"{self.name} — {self.price} {self.currency}"


class Testimonial(models.Model):
    """
    Model for customer testimonials displayed on the landing page.
    """
    name = models.CharField(
        max_length=255,
        verbose_name=_('Имя')
    )
    role = models.CharField(
        max_length=255,
        verbose_name=_('Должность / Город')
    )
    content = models.TextField(
        verbose_name=_('Текст отзыва')
    )
    rating = models.PositiveSmallIntegerField(
        default=5,
        verbose_name=_('Рейтинг')
    )
    avatar_color = models.CharField(
        max_length=7,
        default='#2563eb',
        verbose_name=_('Цвет аватара')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Активен')
    )
    sort_order = models.PositiveIntegerField(
        default=0,
        verbose_name=_('Порядок сортировки')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания')
    )

    class Meta:
        verbose_name = _('Отзыв')
        verbose_name_plural = _('Отзывы')
        ordering = ['sort_order', '-created_at']

    def __str__(self):
        return f"{self.name} — {self.role[:30]}" if self.role else self.name

class City(models.TextChoices):
    BISHKEK = 'bishkek', _('Бишкек')
    OSH = 'osh', _('Ош')
    JALAL_ABAD = 'jalal-abad', _('Джалал-Абад')
    KARAKOL = 'karakol', _('Каракол')
    NARYN = 'naryn', _('Нарын')
    TALAS = 'talas', _('Талас')
    BATKEN = 'batken', _('Баткен')
    TOKMOK = 'tokmok', _('Токмок')
    KYZYL_KIYA = 'kyzyl-kiya', _('Кызыл-Кия')
    BALYKCHY = 'balykchy', _('Балыкчы')
    KANT = 'kant', _('Кант')
    KARA_BALTA = 'kara-balta', _('Кара-Балта')
    MAILUU_SUU = 'mailuu-suu', _('Майлуу-Суу')
    TASH_KUMYR = 'tash-kumyr', _('Таш-Кумыр')
    KERBEN = 'kerben', _('Кербен')
    ISFANA = 'isfana', _('Исфана')
    NOOKAT = 'nookat', _('Ноокат')
    SULUKTA = 'sulukta', _('Сулюкта')
    CHOLPON_ATA = 'cholpon-ata', _('Чолпон-Ата')
    KOCHKOR_ATA = 'kochkor-ata', _('Кочкор-Ата')


class RegistrationRequest(models.Model):
    """
    Model for storing account registration requests from the landing page.
    """
    name = models.CharField(
        max_length=255,
        verbose_name=_('Имя')
    )
    phone = models.CharField(
        max_length=20,
        verbose_name=_('Телефон')
    )
    city = models.CharField(
        max_length=50,
        choices=City.choices,
        blank=True,
        verbose_name=_('Город')
    )
    email = models.EmailField(
        blank=True,
        verbose_name=_('Email')
    )
    organization_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Название организации')
    )
    comment = models.TextField(
        blank=True,
        verbose_name=_('Комментарий')
    )
    status = models.CharField(
        max_length=20,
        choices=RequestStatus.choices,
        default=RequestStatus.PENDING,
        verbose_name=_('Статус')
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Дата создания')
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_('Дата обновления')
    )

    class Meta:
        verbose_name = _('Заявка на регистрацию')
        verbose_name_plural = _('Заявки на регистрацию')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - {self.phone} ({self.get_status_display()})"

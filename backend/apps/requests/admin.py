"""
Enhanced admin configuration for Registration Requests app.
"""
from django.contrib import admin, messages
from django.utils.translation import gettext_lazy as _
from django.utils.html import format_html
from django.utils import timezone
from django.http import HttpResponseRedirect
from django.urls import path, reverse
from django.shortcuts import render
from django.contrib.auth import get_user_model
from .models import RegistrationRequest, RequestStatus, Testimonial, PricingPlan

User = get_user_model()


class HasEmailFilter(admin.SimpleListFilter):
    """Filter requests by whether they have an email specified."""
    title = _('Наличие email')
    parameter_name = 'has_email'

    def lookups(self, request, model_admin):
        return [
            ('yes', _('С email')),
            ('no', _('Без email')),
        ]

    def queryset(self, request, queryset):
        if self.value() == 'yes':
            return queryset.exclude(email='')
        if self.value() == 'no':
            return queryset.filter(email='')


class HasOrganizationFilter(admin.SimpleListFilter):
    """Filter requests by whether they specified an organization."""
    title = _('Наличие организации')
    parameter_name = 'has_org'

    def lookups(self, request, model_admin):
        return [
            ('yes', _('С организацией')),
            ('no', _('Без организации')),
        ]

    def queryset(self, request, queryset):
        if self.value() == 'yes':
            return queryset.exclude(organization_name='')
        if self.value() == 'no':
            return queryset.filter(organization_name='')


@admin.register(RegistrationRequest)
class RegistrationRequestAdmin(admin.ModelAdmin):
    """Enhanced admin for RegistrationRequest model."""

    list_display = [
        'colored_status',
        'name',
        'phone',
        'city_display',
        'email_display',
        'organization_short',
        'comment_preview',
        'created_at_display',
        'age_display',
    ]
    list_display_links = ['name']
    list_filter = [
        'status',
        'city',
        HasEmailFilter,
        HasOrganizationFilter,
        'created_at',
    ]
    search_fields = ['name', 'phone', 'email', 'organization_name', 'comment']
    readonly_fields = ['created_at', 'updated_at', 'created_at_display']
    date_hierarchy = 'created_at'
    list_per_page = 25
    list_max_show_all = 200
    save_on_top = True

    fieldsets = (
        (_('Контактная информация'), {
            'fields': ('name', 'phone', 'city', 'email', 'organization_name'),
        }),
        (_('Детали заявки'), {
            'fields': ('comment', 'status'),
        }),
        (_('Временные метки'), {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    # ─── Custom display helpers ───────────────────────────────

    def city_display(self, obj):
        """Show city with an icon."""
        if not obj.city:
            return format_html('<span style="color:#999;">—</span>')
        return format_html('<i class="fas fa-map-marker-alt" style="color:#6366f1;margin-right:4px"></i>{}', obj.get_city_display())
    city_display.short_description = _('Город')
    city_display.admin_order_field = 'city'

    def colored_status(self, obj):
        """Render status as a colored badge."""
        colors = {
            RequestStatus.PENDING: 'warning',
            RequestStatus.APPROVED: 'success',
            RequestStatus.REJECTED: 'danger',
        }
        color = colors.get(obj.status, 'secondary')
        return format_html(
            '<span class="badge badge-{color}">{status}</span>',
            color=color,
            status=obj.get_status_display(),
        )
    colored_status.short_description = _('Статус')
    colored_status.admin_order_field = 'status'

    def email_display(self, obj):
        """Show email with mailto link if present."""
        if obj.email:
            return format_html('<a href="mailto:{email}">{email}</a>', email=obj.email)
        return format_html('<span style="color:#999;">—</span>')
    email_display.short_description = _('Email')
    email_display.admin_order_field = 'email'

    def organization_short(self, obj):
        """Truncate long organization names."""
        if not obj.organization_name:
            return format_html('<span style="color:#999;">—</span>')
        name = obj.organization_name
        if len(name) > 25:
            name = name[:25] + '…'
        return name
    organization_short.short_description = _('Организация')
    organization_short.admin_order_field = 'organization_name'

    def comment_preview(self, obj):
        """Show first 60 chars of comment."""
        if not obj.comment:
            return format_html('<span style="color:#999;">—</span>')
        text = obj.comment[:60]
        if len(obj.comment) > 60:
            text += '…'
        return text
    comment_preview.short_description = _('Комментарий')

    def created_at_display(self, obj):
        """Format created_at for display."""
        return obj.created_at.strftime('%d.%m.%Y %H:%M')
    created_at_display.short_description = _('Создана')
    created_at_display.admin_order_field = 'created_at'

    def age_display(self, obj):
        """Show how long ago the request was created."""
        delta = timezone.now() - obj.created_at
        days = delta.days
        hours = delta.seconds // 3600
        if days > 0:
            return format_html(
                '<span title="{date}">{days} дн.</span>',
                date=obj.created_at.strftime('%d.%m.%Y %H:%M'),
                days=days,
            )
        return format_html(
            '<span style="color:#e67e22;" title="{date}">{hours} ч.</span>',
            date=obj.created_at.strftime('%d.%m.%Y %H:%M'),
            hours=hours,
        )
    age_display.short_description = _('Возраст')
    age_display.admin_order_field = 'created_at'

    # ─── Actions ───────────────────────────────────────────────

    actions = [
        'approve_requests',
        'reject_requests',
        'approve_and_create_user',
        'send_notification',
    ]

    def approve_requests(self, request, queryset):
        updated = queryset.update(status=RequestStatus.APPROVED)
        self.message_user(
            request,
            _('✅ {count} заявок одобрено').format(count=updated),
            messages.SUCCESS,
        )
    approve_requests.short_description = _('✅ Одобрить выбранные заявки')

    def reject_requests(self, request, queryset):
        updated = queryset.update(status=RequestStatus.REJECTED)
        self.message_user(
            request,
            _('❌ {count} заявок отклонено').format(count=updated),
            messages.WARNING,
        )
    reject_requests.short_description = _('❌ Отклонить выбранные заявки')

    def approve_and_create_user(self, request, queryset):
        """Approve selected requests and pre-fill user creation form."""
        if queryset.count() != 1:
            self.message_user(
                request,
                _('Выберите ровно одну заявку для создания пользователя.'),
                messages.ERROR,
            )
            return

        req = queryset.first()
        if req.status == RequestStatus.APPROVED:
            self.message_user(
                request,
                _('Заявка уже одобрена.'),
                messages.WARNING,
            )
            return

        # Approve first
        req.status = RequestStatus.APPROVED
        req.save()

        # Pre-fill user creation — redirect to Django's user add page with params
        username_base = req.email.split('@')[0] if req.email else req.name.lower().replace(' ', '_')
        url = (
            reverse('admin:users_user_add')
            + f'?username={username_base}'
            + f'&first_name={req.name.split()[0] if req.name.split() else ""}'
            + f'&last_name={" ".join(req.name.split()[1:]) if len(req.name.split()) > 1 else ""}'
            + f'&email={req.email}'
        )
        self.message_user(
            request,
            _('✅ Заявка одобрена! Заполните данные пользователя.'),
            messages.SUCCESS,
        )
        return HttpResponseRedirect(url)
    approve_and_create_user.short_description = _('👤 Одобрить и создать пользователя')

    def send_notification(self, request, queryset):
        """Manually resend Telegram notification for selected requests."""
        sent = 0
        for req in queryset:
            try:
                from bot_service.notifier import notify_new_request
                if notify_new_request(req):
                    sent += 1
            except Exception as e:
                self.message_user(
                    request,
                    _('Ошибка отправки для {name}: {error}').format(name=req.name, error=str(e)),
                    messages.ERROR,
                )
        if sent:
            self.message_user(
                request,
                _('📨 Уведомление отправлено для {count} заявок').format(count=sent),
                messages.SUCCESS,
            )
    send_notification.short_description = _('📨 Отправить уведомление в Telegram')

    # ─── Custom admin URLs ─────────────────────────────────────

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                'dashboard-stats/',
                self.admin_site.admin_view(self.dashboard_stats),
                name='requests-dashboard-stats',
            ),
        ]
        return custom_urls + urls

    def dashboard_stats(self, request):
        """Return JSON-like stats for Jazzmin dashboard widget."""
        from django.http import JsonResponse
        stats = {
            'pending': RegistrationRequest.objects.filter(status=RequestStatus.PENDING).count(),
            'approved': RegistrationRequest.objects.filter(status=RequestStatus.APPROVED).count(),
            'rejected': RegistrationRequest.objects.filter(status=RequestStatus.REJECTED).count(),
            'total': RegistrationRequest.objects.count(),
            'today': RegistrationRequest.objects.filter(
                created_at__date=timezone.now().date()
            ).count(),
        }
        return JsonResponse(stats)


@admin.register(PricingPlan)
class PricingPlanAdmin(admin.ModelAdmin):
    """Admin for PricingPlan model."""

    list_display = [
        'name',
        'price_display',
        'features_count',
        'is_popular',
        'is_active',
        'sort_order',
    ]
    list_display_links = ['name']
    list_filter = ['is_active', 'is_popular']
    search_fields = ['name', 'description']
    list_editable = ['is_active', 'is_popular', 'sort_order']
    ordering = ['sort_order', 'price']

    fieldsets = (
        (_('Основное'), {
            'fields': ('name', 'price', 'currency', 'description'),
        }),
        (_('Возможности'), {
            'fields': ('features',),
            'description': _('Введите список возможностей в формате JSON, например: ["До 3 кассиров", "Основные операции"]'),
        }),
        (_('Настройки'), {
            'fields': ('is_popular', 'is_active', 'sort_order', 'button_text'),
        }),
    )

    def price_display(self, obj):
        return format_html(
            '<strong>{}</strong> <span style="color:#999;">{}</span>',
            f"{obj.price:,.0f}".replace(',', ' '),
            obj.currency
        )
    price_display.short_description = _('Цена')
    price_display.admin_order_field = 'price'

    def features_count(self, obj):
        count = len(obj.features) if obj.features else 0
        return format_html(
            '<span style="color:#10b981;">{} {}</span>',
            count,
            _('опций') if count != 1 else _('опция')
        )
    features_count.short_description = _('Опций')


@admin.register(Testimonial)
class TestimonialAdmin(admin.ModelAdmin):
    """Admin for Testimonial model."""

    list_display = [
        'name',
        'role',
        'content_preview',
        'rating_stars',
        'is_active',
        'sort_order',
    ]
    list_display_links = ['name']
    list_filter = ['is_active', 'rating']
    search_fields = ['name', 'role', 'content']
    list_editable = ['is_active', 'sort_order']
    ordering = ['sort_order', '-created_at']

    fieldsets = (
        (_('Информация'), {
            'fields': ('name', 'role', 'content', 'rating'),
        }),
        (_('Настройки отображения'), {
            'fields': ('avatar_color', 'is_active', 'sort_order'),
        }),
    )

    def content_preview(self, obj):
        """Show first 80 chars of content."""
        text = obj.content[:80]
        if len(obj.content) > 80:
            text += '…'
        return text
    content_preview.short_description = _('Отзыв')

    def rating_stars(self, obj):
        """Render rating as star icons."""
        return format_html(
            '<span style="color:#f59e0b;font-size:14px;">{}</span>',
            '★' * obj.rating + '☆' * (5 - obj.rating)
        )
    rating_stars.short_description = _('Рейтинг')
    rating_stars.admin_order_field = 'rating'


# ─── Jazzmin Dashboard Widget ─────────────────────────────────

class RequestDashboardWidget:
    """
    Jazzmin dashboard widget showing registration request statistics.
    Register in JAZZMIN_SETTINGS['custom_links'] or as a template widget.
    """

    title = _('📋 Заявки на регистрацию')
    template = 'admin/widgets/request_stats.html'

    def get_context(self, request):
        now = timezone.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        return {
            'pending_count': RegistrationRequest.objects.filter(status=RequestStatus.PENDING).count(),
            'approved_count': RegistrationRequest.objects.filter(status=RequestStatus.APPROVED).count(),
            'rejected_count': RegistrationRequest.objects.filter(status=RequestStatus.REJECTED).count(),
            'total_count': RegistrationRequest.objects.count(),
            'today_count': RegistrationRequest.objects.filter(created_at__gte=today_start).count(),
            'latest_requests': RegistrationRequest.objects.order_by('-created_at')[:5],
        }

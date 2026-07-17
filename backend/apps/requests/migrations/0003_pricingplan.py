"""
Migration for PricingPlan model.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('requests', '0002_testimonial'),
    ]

    operations = [
        migrations.CreateModel(
            name='PricingPlan',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, verbose_name='Название тарифа')),
                ('price', models.DecimalField(decimal_places=2, max_digits=10, verbose_name='Цена')),
                ('currency', models.CharField(default='сом/мес', max_length=50, verbose_name='Валюта / период')),
                ('description', models.CharField(blank=True, max_length=500, verbose_name='Описание')),
                ('features', models.JSONField(blank=True, default=list, verbose_name='Возможности (JSON-список)')),
                ('is_popular', models.BooleanField(default=False, verbose_name='Популярный тариф')),
                ('is_active', models.BooleanField(default=True, verbose_name='Активен')),
                ('sort_order', models.PositiveIntegerField(default=0, verbose_name='Порядок сортировки')),
                ('button_text', models.CharField(default='Начать', max_length=100, verbose_name='Текст кнопки')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
            ],
            options={
                'verbose_name': 'Тариф',
                'verbose_name_plural': 'Тарифы',
                'ordering': ['sort_order', 'price'],
            },
        ),
    ]

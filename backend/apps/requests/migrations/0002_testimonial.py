"""
Migration for Testimonial model.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('requests', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Testimonial',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, verbose_name='Имя')),
                ('role', models.CharField(max_length=255, verbose_name='Должность / Город')),
                ('content', models.TextField(verbose_name='Текст отзыва')),
                ('rating', models.PositiveSmallIntegerField(default=5, verbose_name='Рейтинг')),
                ('avatar_color', models.CharField(default='#2563eb', max_length=7, verbose_name='Цвет аватара')),
                ('is_active', models.BooleanField(default=True, verbose_name='Активен')),
                ('sort_order', models.PositiveIntegerField(default=0, verbose_name='Порядок сортировки')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Дата создания')),
            ],
            options={
                'verbose_name': 'Отзыв',
                'verbose_name_plural': 'Отзывы',
                'ordering': ['sort_order', '-created_at'],
            },
        ),
    ]

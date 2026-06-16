# My Exchange - Backend

Backend для системы автоматизации пункта обмена валют.

## Технологии

- **Framework**: Django 5.0 + Django REST Framework
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Authentication**: JWT (SimpleJWT)
- **Documentation**: DRF Spectacular (OpenAPI/Swagger)

## Структура проекта

```
backend/
├── config/                 # Основной модуль Django
│   ├── settings.py        # Настройки проекта
│   ├── urls.py            # Корневые URL
│   └── wsgi.py            # WSGI конфигурация
├── apps/                   # Приложения Django
│   ├── users/             # Пользователи и авторизация
│   ├── currencies/        # Валюты и курсы
│   ├── operations/        # Операции обмена
│   ├── cash/              # Управление кассой
│   ├── reports/           # Отчёты и экспорт
│   ├── logs/              # Логирование и аудит
│   ├── analytics/         # Аналитика и статистика
│   └── notifications/     # Уведомления
├── utils/                  # Утилиты
│   └── backup.py          # Резервное копирование
├── media/                  # Медиа файлы
├── static/                 # Статические файлы
├── backups/                # Резервные копии БД
└── requirements.txt        # Зависимости Python
```

## Быстрый старт

### Через Docker (рекомендуется)

```bash
# Запуск всех сервисов
docker-compose up -d

# Инициализация БД произойдет автоматически
# Будут созданы:
# - Администратор: admin / admin123
# - Кассир: cashier1 / cashier123

# Доступ к API: http://localhost:8000
# Документация Swagger: http://localhost:8000/api/docs/
```

### Локальная разработка

```bash
# 1. Создать виртуальное окружение
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Установить зависимости
pip install -r requirements.txt

# 3. Создать .env файл
cp .env.example .env

# 4. Запустить PostgreSQL и Redis
# (или использовать docker-compose только для БД)
docker-compose up -d db redis

# 5. Применить миграции
python manage.py migrate

# 6. Инициализировать данные
python manage.py init_data

# 7. Запустить сервер
python manage.py runserver
```

## API Endpoints

### Авторизация
- `POST /api/auth/login/` - Вход (получение JWT токенов)
- `POST /api/auth/refresh/` - Обновление токена
- `POST /api/auth/logout/` - Выход
- `POST /api/auth/users/` - Создание пользователя
- `GET /api/auth/me/` - Текущий пользователь
- `POST /api/auth/change_password/` - Смена пароля

### Валюты
- `GET /api/currencies/currencies/` - Список валют
- `GET /api/currencies/currencies/active/` - Активные валюты с курсами
- `POST /api/currencies/currencies/` - Создание валюты (admin)
- `GET /api/currencies/rates/` - Курсы обмена
- `POST /api/currencies/rates/` - Установка курса (admin/senior)
- `GET /api/currencies/rate-history/` - История изменений курсов

### Операции
- `GET /api/operations/operations/` - Список операций
- `POST /api/operations/operations/` - Создание операции
- `PUT /api/operations/operations/{id}/` - Редактирование
- `POST /api/operations/operations/{id}/cancel/` - Отмена операции
- `GET /api/operations/operations/{id}/history/` - История изменений
- `GET /api/operations/operations/today_stats/` - Статистика за день

### Касса
- `GET /api/cash/balances/` - Остатки кассы
- `GET /api/cash/balances/summary/` - Сводка по кассе
- `POST /api/cash/transactions/` - Кассовая операция
- `GET /api/cash/registers/current/` - Текущая смена
- `POST /api/cash/registers/open/` - Открыть смену
- `POST /api/cash/registers/{id}/close/` - Закрыть смену

### Отчёты
- `GET /api/reports/daily/` - Отчёт за день
- `GET /api/reports/monthly/` - Отчёт за месяц
- `GET /api/reports/cashier/` - Отчёт по кассиру
- `GET /api/reports/export/?format=csv&_=operations` - Экспорт данных

### Логи
- `GET /api/logs/audit/` - Логи аудита

### Аналитика
- `GET /api/analytics/dashboard/` - Статистика для главной панели
- `GET /api/analytics/operations/` - Аналитика операций
- `GET /api/analytics/profitability/` - Рентабельность
- `GET /api/analytics/cashier-load/` - Нагрузка кассиров

### Уведомления
- `GET /api/notifications/` - Получить уведомления
- `POST /api/notifications/send/` - Отправить уведомление (admin)

## Ролевая модель

### Кассир (cashier)
- Создание операций
- Просмотр своих операций
- Работа с кассой
- Просмотр своих отчётов

### Старший кассир (senior_cashier)
- Все права кассира
- Просмотр операций всех кассиров
- Редактирование операций
- Установка курсов валют
- Просмотр отчётов всех кассиров

### Администратор (admin)
- Полный доступ ко всем функциям
- Управление пользователями
- Просмотр логов аудита
- Настройка системы
- Создание резервных копий

## Экспорт данных

Поддерживаемые форматы:
- **CSV** - для импорта в Excel
- **XLSX** - Excel формат
- **JSON** - для интеграций

Параметры экспорта:
- `format` - формат файла (csv, xlsx, json)
- `type` - тип данных (operations, cash, report)
- `date_from`, `date_to` - период

## Резервное копирование

```python
from utils.backup import DatabaseBackup

backup = DatabaseBackup()

# Создать резервную копию
result = backup.create_backup()

# Восстановить из копии
result = backup.restore_backup('path/to/backup.sql.gz')

# Список доступных копий
backups = backup.list_backups()
```

## Логирование

Все действия пользователей логируются в системе:
- Входы/выходы
- Создание/изменение/удаление операций
- Изменение курсов
- Кассовые операции
- Экспорт данных

Логи доступны через API `/api/logs/audit/`

## Безопасность

- JWT аутентификация
- Ролевая модель доступа
- Аудит всех действий
- HTTPS в production
- Защита от CORS
- Валидация данных

## Тестирование

```bash
# Запустить тесты
python manage.py test

# С покрытием
coverage run manage.py test
coverage report
```

## Production настройки

1. Установите `DEBUG=False`
2. Смените `SECRET_KEY` на случайную строку
3. Настройте `ALLOWED_HOSTS`
4. Используйте HTTPS
5. Настройте регулярное резервное копирование
6. Мониторинг логов

## Лицензия

Внутренняя разработка для My Exchange.

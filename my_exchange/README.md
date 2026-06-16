# My Exchange - Мобильное приложение для обменника валют

Flutter-приложение для автоматизации работы обменного пункта валюты с современным UI и чистой архитектурой.

## 📱 Возможности

### Аутентификация
- Вход в систему по логину/паролю
- JWT токены с автоматическим обновлением
- Безопасное хранение учетных данных
- Разделение прав доступа (Кассир, Старший кассир, Администратор)

### Операции обмена
- Создание операций покупки/продажи валюты
- Автоматический расчет суммы по курсу
- История операций с фильтрацией
- Статистика за сегодня
- Отмена операций (полная/частичная)
- Информация о клиенте

### Касса
- Открытие/закрытие кассовой смены
- Учет остатков по всем валютам
- Внесение/выдача наличности
- Инкассация
- Контроль минимальных остатков

### Валюты
- Список активных валют
- Курсы покупки/продажи
- История изменений курсов
- Добавление/редактирование валют

### Аналитика
- Дашборд с основной статистикой
- Популярные валюты
- Статистика по кассирам
- Графики и отчеты

## 🏗 Архитектура

Приложение построено по принципам **Clean Architecture**:

```
lib/
├── core/                    # Ядро приложения
│   ├── constants/          # Константы и настройки
│   ├── errors/             # Обработка ошибок
│   ├── network/            # Сетевой клиент (Dio)
│   ├── theme/              # Тема и цвета
│   └── utils/              # Утилиты и форматтеры
│
├── data/                    # Слой данных
│   ├── datasources/        # Источники данных (API)
│   ├── models/             # Модели данных
│   └── repositories/       # Реализации репозиториев
│
├── domain/                  # Доменный слой
│   ├── entities/           # Бизнес-сущности
│   ├── repositories/       # Интерфейсы репозиториев
│   └── usecases/           # Бизнес-логика
│
├── presentation/            # Слой представления
│   ├── providers/          # State management (Provider)
│   ├── screens/            # Экраны
│   └── widgets/            # Переиспользуемые виджеты
│
├── features/                # Функциональные модули
│   ├── auth/               # Аутентификация
│   ├── operations/         # Операции обмена
│   ├── cash/               # Касса
│   ├── currencies/         # Валюты
│   ├── analytics/          # Аналитика
│   └── reports/            # Отчеты
│
└── di/                      # Dependency Injection
    └── service_locator.dart
```

## 🛠 Технологии

### State Management
- **Provider** - Управление состоянием

### Network
- **Dio** - HTTP клиент
- **Flutter Secure Storage** - Безопасное хранение токенов

### Architecture
- **Clean Architecture** - Разделение на слои
- **Repository Pattern** - Абстракция источников данных
- **Use Cases** - Бизнес-логика

### UI
- **Material 3** - Современный дизайн
- **Custom Theme** - Фирменный стиль
- **Responsive** - Адаптивный интерфейс

### Utilities
- **intl** - Форматирование дат и чисел
- **equatable** - Сравнение объектов
- **dartz** - Functional programming (Either)
- **get_it** - Service Locator

## 🚀 Запуск

### Требования
- Flutter SDK >= 3.12.1
- Dart SDK >= 3.0
- Android Studio / VS Code

### Установка

1. Клонируйте репозиторий:
```bash
git clone <repository_url>
cd my_exchange
```

2. Установите зависимости:
```bash
flutter pub get
```

3. Сгенерируйте модели (при необходимости):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Настройте API endpoint:
   - Откройте `lib/core/constants/api_constants.dart`
   - Измените `baseUrl` на адрес вашего сервера

5. Запустите приложение:
```bash
flutter run
```

## 📡 API Integration

Приложение работает с Django REST API. Основные эндпоинты:

| Модуль | Endpoint | Описание |
|--------|----------|----------|
| Auth | `/api/auth/login/` | Вход |
| Auth | `/api/auth/refresh/` | Обновление токена |
| Operations | `/api/operations/operations/` | Операции |
| Cash | `/api/cash/registers/` | Кассовые смены |
| Currencies | `/api/currencies/currencies/` | Валюты |
| Analytics | `/api/analytics/dashboard/` | Дашборд |

## 🔐 Безопасность

- JWT токены с автоматическим обновлением
- Безопасное хранение в Flutter Secure Storage
- HTTPS соединение (рекомендуется для production)
- Защита от повторной отправки запросов

## 🎨 UI Компоненты

- Карточки операций с цветовой индикацией
- Навигационная панель (Bottom Navigation)
- Диалоговые окна для действий
- Индикаторы загрузки (Shimmer)
- Кастомные кнопки и поля ввода
- Градиентные элементы

## 📦 Структура данных

### User
```dart
{
  id: int,
  username: String,
  email: String?,
  role: UserRole,
  firstName: String?,
  lastName: String?,
  phone: String?,
  isActive: bool
}
```

### Operation
```dart
{
  id: String,
  operationNumber: String,
  operationType: OperationType,
  status: OperationStatus,
  currency: Currency,
  rate: double,
  amount: double,
  totalAmount: double,
  cashier: User,
  clientName: String?,
  createdAt: DateTime
}
```

### CashBalance
```dart
{
  id: int,
  currency: Currency,
  balance: double,
  reserved: double,
  availableBalance: double
}
```

## 🔧 Конфигурация

### API URL
```dart
// lib/core/constants/api_constants.dart
const String baseUrl = 'http://your-api-url.com';
```

### Таймауты
```dart
static const int connectionTimeout = 30000; // 30 секунд
static const int receiveTimeout = 30000;    // 30 секунд
```

## 📝 Лицензия

Проект создан для образовательных целей.

## 👥 Авторы

- NLP-Core-Team

## 📞 Поддержка

Для вопросов и предложений обращайтесь к команде разработки.

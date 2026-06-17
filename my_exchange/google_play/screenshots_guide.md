# 📸 Инструкция по созданию скриншотов для Google Play

## Требования к скриншотам Google Play
- **Размер:** min 320px, max 3840px (рекомендуется 1080×2400 px)
- **Соотношение сторон:** 16:9 или 9:16
- **Минимум:** 2 скриншота (рекомендуется 8)

---

## Способ 1: Через ADB (с подключённым устройством)

### 1. Подключите устройство
```bash
adb devices
```

### 2. Запустите приложение
```bash
cd /Users/sm1le/Desktop/My\ Exchange/my_exchange
flutter run
```

### 3. Сделайте скриншоты

После каждого шага — переключайтесь на нужный экран и делайте скриншот:

```bash
# Экран 1 - Логин
adb shell screencap -p /sdcard/screenshot_01_login.png
adb pull /sdcard/screenshot_01_login.png /Users/sm1le/Desktop/screenshots/

# Экран 2 - Операции
adb shell screencap -p /sdcard/screenshot_02_operations.png
adb pull /sdcard/screenshot_02_operations.png /Users/sm1le/Desktop/screenshots/

# Экран 3 - Создание операции
adb shell screencap -p /sdcard/screenshot_03_new_operation.png
adb pull /sdcard/screenshot_03_new_operation.png /Users/sm1le/Desktop/screenshots/

# Экран 4 - Касса
adb shell screencap -p /sdcard/screenshot_04_cash.png
adb pull /sdcard/screenshot_04_cash.png /Users/sm1le/Desktop/screenshots/

# Экран 5 - Транзакция
adb shell screencap -p /sdcard/screenshot_05_transaction.png
adb pull /sdcard/screenshot_05_transaction.png /Users/sm1le/Desktop/screenshots/

# Экран 6 - Валюты
adb shell screencap -p /sdcard/screenshot_06_currencies.png
adb pull /sdcard/screenshot_06_currencies.png /Users/sm1le/Desktop/screenshots/

# Экран 7 - Аналитика - сводка
adb shell screencap -p /sdcard/screenshot_07_analytics_stats.png
adb pull /sdcard/screenshot_07_analytics_stats.png /Users/sm1le/Desktop/screenshots/

# Экран 8 - Аналитика - графики
adb shell screencap -p /sdcard/screenshot_08_analytics_charts.png
adb pull /sdcard/screenshot_08_analytics_charts.png /Users/sm1le/Desktop/screenshots/
```

---

## Способ 2: Через утилиту Flutter Screenshot (автоматический)

### Установка
```bash
flutter pub global activate screenshot
```

### Создание скриншотов
```bash
cd /Users/sm1le/Desktop/My\ Exchange/my_exchange
flutter screenshot -d <device_id> -o ~/Desktop/screenshots/screenshot_01_login.png
```

---

## Способ 3: Вручную на устройстве

1. Откройте приложение
2. Нажмите **Power + Volume Down** одновременно
3. Скриншот сохранится в галерее
4. Перенесите на компьютер через USB кабель

---

## Список скриншотов

| № | Экран | Действие для захвата |
|---|-------|---------------------|
| 1 | **Экран входа** | Логотип, поля логина/пароля, кнопка «Войти» |
| 2 | **Список операций** | Today-статистика (оборот, покупки/продажи) и список операций |
| 3 | **Новая операция** | Форма с выбором типа, валюты, курса, суммы и итога |
| 4 | **Касса** | Карточка статуса смены и список остатков по валютам |
| 5 | **Транзакция** | Диалог внесения/выдачи с выбором валюты и суммы |
| 6 | **Курсы валют** | Список валют с курсами покупки (зелёный) и продажи (красный) |
| 7 | **Аналитика — обзор** | Статистика: операции, оборот, клиенты, курсы |
| 8 | **Аналитика — графики** | График по дням, популярные валюты, маржа |

---

## Обработка скриншотов (рекомендуется)

1. Откройте скриншоты в любом редакторе (Canva, Photoshop, GIMP, Snapseed)
2. Обрежьте до стандартного размера (рекомендуется 1080×1920 или 1080×2400)
3. При необходимости добавьте лёгкий оверлей с текстом или стрелками
4. Загрузите все 8 скриншотов в Google Play Console

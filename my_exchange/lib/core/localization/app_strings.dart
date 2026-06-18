/// Localized strings for the app.
/// Keys are the same across languages; values are the translations.
class AppStrings {
  const AppStrings._();

  /// All supported locales.
  static const List<String> supportedLocales = ['ru', 'ky'];
  static const String defaultLocale = 'ru';

  /// Map of locale -> (string key -> translated value).
  static const Map<String, Map<String, String>> _strings = {
    'ru': _ru,
    'ky': _kg,
  };

  /// Returns the translated string for [key] in [locale].
  /// Falls back to Russian, then to the key itself.
  static String t(String key, {String locale = 'ru'}) {
    return _strings[locale]?[key] ??
        _strings['ru']?[key] ??
        key;
  }

  /// Convenience: get all key-value pairs for a locale.
  static Map<String, String> forLocale(String locale) {
    return _strings[locale] ?? _strings['ru']!;
  }

  // ─── Russian ────────────────────────────────────────────────────
  static const Map<String, String> _ru = {
    // App
    'app_name': 'My Exchange',
    'app_title': 'Моя волюта',

    // Navigation
    'nav_operations': 'Операции',
    'nav_cash': 'Касса',
    'nav_currencies': 'Валюты',
    'nav_analytics': 'Аналитика',
    'nav_settings': 'Профиль',

    // Login
    'login_title': 'Вход в систему',
    'login_username': 'Имя пользователя',
    'login_password': 'Пароль',
    'login_button': 'Войти',
    'login_error': 'Ошибка входа',
    'login_username_required': 'Введите имя пользователя',
    'login_password_required': 'Введите пароль',
    'login_password_min': 'Пароль должен быть не менее 6 символов',
    'login_version': 'Версия',

    // Settings / Profile
    'settings_title': 'Профиль и настройки',
    'settings_profile': 'Профиль',
    'settings_user_info': 'Информация о пользователе',
    'settings_role': 'Должность',
    'settings_email': 'Email',
    'settings_phone': 'Телефон',
    'settings_language': 'Язык',
    'settings_language_ru': 'Русский',
    'settings_language_kg': 'Кыргызча',
    'settings_app_version': 'Версия приложения',
    'settings_logout': 'Выйти',
    'settings_logout_confirm': 'Вы уверены, что хотите выйти?',
    'settings_logout_confirm_desc': 'Для повторного входа потребуется ввести логин и пароль.',
    'settings_cancel': 'Отмена',
    'settings_confirm': 'Да, выйти',
    'settings_privacy_policy': 'Политика конфиденциальности',
    'settings_contact_support': 'Связаться с поддержкой',
    'settings_delete_account': 'Запросить удаление аккаунта',
    'settings_delete_account_desc': 'Отправить запрос на удаление вашего аккаунта и всех связанных данных.',
    'settings_delete_account_confirm': 'Запрос отправлен. С вами свяжутся в ближайшее время.',
    'settings_support_email': 'salievyt@gmail.com',
    'settings_privacy_note': 'Нажимая «Выйти», вы завершаете текущую сессию.',

    // Operations
    'operations_title': 'Операции',
    'operations_create': 'Операция',
    'operations_empty': 'Нет операций',
    'operations_load': 'Загрузить',
    'operations_today': 'Сегодня',
    'operations_buys': 'Покупки',
    'operations_sells': 'Продажи',
    'operations_buy': 'Покупка',
    'operations_sell': 'Продажа',

    // Cash
    'cash_title': 'Касса',
    'cash_balances': 'Остатки',
    'cash_register_open': 'Смена открыта',
    'cash_register_closed': 'Смена не открыта',
    'cash_register_open_desc': 'Откройте смену для начала работы',
    'cash_register_close': 'Закрыть смену',
    'cash_open_shift': 'Открыть смену',
    'cash_transaction': 'Транзакция',
    'cash_available': 'Доступно',
    'cash_reserved': 'Зарезервировано',
    'cash_cashier': 'Кассир',
    'cash_opened_at': 'Открыта',
    'cash_no_data': 'Нет данных',

    // Currencies
    'currencies_title': 'Валюты',
    'currencies_buy': 'Покупка',
    'currencies_sell': 'Продажа',

    // Analytics
    'analytics_title': 'Аналитика',
    'analytics_no_data': 'Нет данных для отображения',
    'analytics_no_data_desc': 'Статистика появится после совершения операций',
    'analytics_overall': 'Общая статистика',
    'analytics_operations_today': 'Операций сегодня',
    'analytics_buys_sells': 'Покупок / Продаж',
    'analytics_turnover': 'Оборот (сом)',
    'analytics_clients': 'Клиентов',
    'analytics_rates': 'Курсы валют',
    'analytics_daily_chart': 'Операции по дням',
    'analytics_popular_currencies': 'Популярные валюты',
    'analytics_profitability': 'Рентабельность (маржа %)',
    'analytics_cashiers': 'Кассиры',
    'analytics_cash_balances': 'Остатки в кассе',

    // General
    'general_retry': 'Повторить',
    'general_refresh': 'Обновить',
    'general_loading': 'Загрузка...',
    'general_error': 'Ошибка',
    'general_success': 'Успешно',
    'general_close': 'Закрыть',
    'general_ops': 'оп.',
    'general_today': 'Сегодня',
    'general_yesterday': 'Вчера',
    'general_just_now': 'Только что',
    'general_min_ago': 'мин. назад',
    'general_hours_ago': 'ч. назад',
    'general_days_ago': 'дн. назад',
    'general_som': 'сом',
  };

  // ─── Kyrgyz ─────────────────────────────────────────────────────
  static const Map<String, String> _kg = {
    // App
    'app_name': 'My Exchange',
    'app_title': 'Моя волюта',

    // Navigation
    'nav_operations': 'Операциялар',
    'nav_cash': 'Касса',
    'nav_currencies': 'Валюталар',
    'nav_analytics': 'Аналитика',
    'nav_settings': 'Профиль',

    // Login
    'login_title': 'Системага кирүү',
    'login_username': 'Колдонуучу аты',
    'login_password': 'Сырсөз',
    'login_button': 'Кирүү',
    'login_error': 'Кирүү катасы',
    'login_username_required': 'Колдонуучу атын жазыңыз',
    'login_password_required': 'Сырсөздү жазыңыз',
    'login_password_min': 'Сырсөз кеминде 6 символ болушу керек',
    'login_version': 'Версия',

    // Settings / Profile
    'settings_title': 'Профиль жана орнотуулар',
    'settings_profile': 'Профиль',
    'settings_user_info': 'Колдонуучу маалыматы',
    'settings_role': 'Кызматы',
    'settings_email': 'Email',
    'settings_phone': 'Телефон',
    'settings_language': 'Тил',
    'settings_language_ru': 'Орусча',
    'settings_language_kg': 'Кыргызча',
    'settings_app_version': 'Колдонмо версиясы',
    'settings_logout': 'Чыгуу',
    'settings_logout_confirm': 'Чыгууга ишенесизби?',
    'settings_logout_confirm_desc': 'Кайра кирүү үчүн логин жана сырсөз керек болот.',
    'settings_cancel': 'Жокко чыгаруу',
    'settings_confirm': 'Ооба, чыгуу',
    'settings_privacy_policy': 'Купуялык саясаты',
    'settings_contact_support': 'Колдоо кызматы',
    'settings_delete_account': 'Аккаунтту жок кылуу',
    'settings_delete_account_desc': 'Аккаунтуңузду жана бардык маалыматтарды жок кылуу өтүнүчүн жөнөтүү.',
    'settings_delete_account_confirm': 'Өтүнүч жөнөтүлдү. Жакында сиз менен байланышабыз.',
    'settings_support_email': 'salievyt@gmail.com',
    'settings_privacy_note': '«Чыгуу» баскычын басуу менен, сиз учурдагы сессияны аяктайсыз.',

    // Operations
    'operations_title': 'Операциялар',
    'operations_create': 'Операция',
    'operations_empty': 'Операциялар жок',
    'operations_load': 'Жүктөө',
    'operations_today': 'Бүгүн',
    'operations_buys': 'Сатып алуулар',
    'operations_sells': 'Сатуулар',
    'operations_buy': 'Сатып алуу',
    'operations_sell': 'Сатуу',

    // Cash
    'cash_title': 'Касса',
    'cash_balances': 'Калдыктар',
    'cash_register_open': 'Смена ачык',
    'cash_register_closed': 'Смена ачык эмес',
    'cash_register_open_desc': 'Ишти баштоо үчүн сменаны ачыңыз',
    'cash_register_close': 'Сменаны жабуу',
    'cash_open_shift': 'Сменаны ачуу',
    'cash_transaction': 'Транзакция',
    'cash_available': 'Жеткиликтүү',
    'cash_reserved': 'Резервделген',
    'cash_cashier': 'Кассир',
    'cash_opened_at': 'Ачылган',
    'cash_no_data': 'Маалымат жок',

    // Currencies
    'currencies_title': 'Валюталар',
    'currencies_buy': 'Сатып алуу',
    'currencies_sell': 'Сатуу',

    // Analytics
    'analytics_title': 'Аналитика',
    'analytics_no_data': 'Көрсөтүү үчүн маалымат жок',
    'analytics_no_data_desc': 'Операциялардан кийин статистика пайда болот',
    'analytics_overall': 'Жалпы статистика',
    'analytics_operations_today': 'Бүгүнкү операциялар',
    'analytics_buys_sells': 'Сатып алуулар / Сатуулар',
    'analytics_turnover': 'Жүгүртүү (сом)',
    'analytics_clients': 'Кардарлар',
    'analytics_rates': 'Валюта курстары',
    'analytics_daily_chart': 'Күндөр боюнча операциялар',
    'analytics_popular_currencies': 'Популярдуу валюталар',
    'analytics_profitability': 'Рентабелдүүлүк (маржа %)',
    'analytics_cashiers': 'Кассирлер',
    'analytics_cash_balances': 'Кассадагы калдыктар',

    // General
    'general_retry': 'Кайталоо',
    'general_refresh': 'Жаңыртуу',
    'general_loading': 'Жүктөлүүдө...',
    'general_error': 'Ката',
    'general_success': 'Ийгиликтүү',
    'general_close': 'Жабуу',
    'general_ops': 'оп.',
    'general_today': 'Бүгүн',
    'general_yesterday': 'Кечээ',
    'general_just_now': 'Жаңы эле',
    'general_min_ago': 'мүн. мурун',
    'general_hours_ago': 'саат. мурун',
    'general_days_ago': 'күн. мурун',
    'general_som': 'сом',
  };
}

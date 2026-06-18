import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_strings.dart';

/// Manages the current app locale and persists the choice.
class LocalizationProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  String _locale = AppStrings.defaultLocale;

  String get locale => _locale;
  bool get isRussian => _locale == 'ru';
  bool get isKyrgyz => _locale == 'ky';

  /// Shorthand to get a translated string for the current locale.
  String t(String key) => AppStrings.t(key, locale: _locale);

  /// Initialize from persisted value.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_localeKey);
    if (saved != null && AppStrings.supportedLocales.contains(saved)) {
      _locale = saved;
      notifyListeners();
    }
  }

  /// Switch locale and persist.
  Future<void> setLocale(String newLocale) async {
    if (!AppStrings.supportedLocales.contains(newLocale)) return;
    if (_locale == newLocale) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale);
  }
}

import 'package:intl/intl.dart';

/// Currency formatter
class CurrencyFormatter {
  static String format(double amount, {String symbol = '', int decimals = 2}) {
    final formatter = NumberFormat.decimalPattern('ru_RU');
    final formatted = formatter.format(amount);
    return symbol.isNotEmpty ? '$formatted $symbol' : formatted;
  }

  static String formatWithSymbol(double amount, String currencyCode) {
    final symbols = {
      'KGS': 'сом',
      'USD': '\$',
      'EUR': '€',
      'RUB': '₽',
      'CNY': '¥',
      'GBP': '£',
    };
    final symbol = symbols[currencyCode] ?? currencyCode;
    return format(amount, symbol: symbol);
  }

  static String formatRate(double rate, {int decimals = 4}) {
    final formatter = NumberFormat.decimalPatternDigits(
      decimalDigits: decimals,
    );
    return formatter.format(rate);
  }

  static double parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }
}

/// Date formatter
class DateFormatter {
  static String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    final formatter = DateFormat(format, 'ru_RU');
    return formatter.format(date);
  }

  static String formatDateTime(
    DateTime dateTime, {
    String format = 'dd.MM.yyyy HH:mm',
  }) {
    final formatter = DateFormat(format, 'ru_RU');
    return formatter.format(dateTime);
  }

  static String formatTime(DateTime time, {String format = 'HH:mm'}) {
    final formatter = DateFormat(format, 'ru_RU');
    return formatter.format(time);
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return formatDate(dateTime);
    }
  }

  static DateTime parse(String dateString) {
    return DateTime.parse(dateString);
  }

  static String formatTodayOrDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Сегодня, ${formatTime(dateTime)}';
    }
    return formatDateTime(dateTime);
  }
}

/// Number formatter
class NumberFormatter {
  static String formatPercentage(double value, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      decimalDigits: decimals,
    );
    return '${formatter.format(value)}%';
  }

  static String formatCompact(int number) {
    final formatter = NumberFormat.compact(locale: 'ru_RU');
    return formatter.format(number);
  }

  static String formatPhone(String phone) {
    // Format: +996 (XXX) XX-XX-XX
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 12 && cleaned.startsWith('996')) {
      return '+${cleaned.substring(0, 3)} (${cleaned.substring(3, 6)}) ${cleaned.substring(6, 8)}-${cleaned.substring(8, 10)}-${cleaned.substring(10, 12)}';
    }
    return phone;
  }
}

/// String extensions
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return substring(0, maxLength - suffix.length) + suffix;
  }

  bool isValidEmail() {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(this);
  }

  bool isValidPhone() {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(this) && length >= 10;
  }
}

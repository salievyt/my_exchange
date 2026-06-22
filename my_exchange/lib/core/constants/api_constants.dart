/// API Base URL
const String baseUrl = 'https://dev.phantom-ink.online';

/// API Endpoints
class ApiEndpoints {
  
  static const String login = '/api/auth/login/';
  static const String refresh = '/api/auth/refresh/';
  static const String users = '/api/auth/users/';
  static const String usersMe = '/api/auth/users/me/';
  static const String logout = '/api/auth/users/logout/';
  static const String changePassword = '/api/auth/users/change_password/';
  static const String loginHistory = '/api/auth/login-history/';

  
  static const String currencies = '/api/currencies/currencies/';
  static const String currenciesActive = '/api/currencies/currencies/active/';
  static const String currencyHistory = '/api/currencies/currencies/';
  static const String rates = '/api/currencies/rates/';
  static const String rateHistory = '/api/currencies/rate-history/';

  
  static const String operations = '/api/operations/operations/';
  static const String operationCancel = '/api/operations/operations/';
  static const String operationHistory = '/api/operations/operations/';
  static const String todayStats = '/api/operations/operations/today_stats/';

  
  static const String cashBalances = '/api/cash/balances/';
  static const String cashBalancesSummary = '/api/cash/balances/summary/';
  static const String cashBalancesLow = '/api/cash/balances/low_balance/';
  static const String cashRegisters = '/api/cash/registers/';
  static const String cashRegistersCurrent = '/api/cash/registers/current/';
  static const String cashRegistersOpen = '/api/cash/registers/open/';
  static const String cashRegistersClose = '/api/cash/registers/';
  static const String cashTransactions = '/api/cash/transactions/';

  
  static const String analyticsDashboard = '/api/analytics/dashboard/';
  static const String analyticsCashierLoad = '/api/analytics/cashier-load/';
  static const String analyticsOperations = '/api/analytics/operations/';
  static const String analyticsProfitability = '/api/analytics/profitability/';

  
  static const String reportsDaily = '/api/reports/daily/';
  static const String reportsMonthly = '/api/reports/monthly/';
  static const String reportsCashier = '/api/reports/cashier/';
  static const String reportsExport = '/api/reports/export/';

  
  static const String notifications = '/api/notifications/';
  static const String notificationsSend = '/api/notifications/send/';
  static const String notificationsError = '/api/notifications/error/';
  static const String notificationsAppVersion = '/api/notifications/app-version/';

  
  static const String auditLogs = '/api/logs/audit/';
}

/// Storage Keys
class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String theme = 'theme';
  static const String language = 'language';
}

/// App Constants
class AppConstants {
  static const String appName = 'My Exchange';
  static const String appVersion = '1.2.0';

  
  static const int defaultPageSize = 20;

  
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  
  static const int currencyDecimals = 2;
  static const int rateDecimals = 4;
}

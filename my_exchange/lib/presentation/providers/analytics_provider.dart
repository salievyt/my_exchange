import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/drf_error_helper.dart';
import '../../core/network/dio_client.dart';
import '../../di/service_locator.dart';

/// Analytics data model
class AnalyticsData {
  final int operationsToday;
  final int buyOperations;
  final int sellOperations;
  final double turnoverToday;
  final int clientsToday;
  final List<Map<String, dynamic>> exchangeRates;
  final List<Map<String, dynamic>> cashBalances;

  const AnalyticsData({
    required this.operationsToday,
    required this.buyOperations,
    required this.sellOperations,
    required this.turnoverToday,
    required this.clientsToday,
    required this.exchangeRates,
    required this.cashBalances,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      operationsToday: json['operations_today'] as int? ?? 0,
      buyOperations: json['buy_operations'] as int? ?? 0,
      sellOperations: json['sell_operations'] as int? ?? 0,
      turnoverToday: (json['turnover_today'] as num?)?.toDouble() ?? 0.0,
      clientsToday: json['clients_today'] as int? ?? 0,
      exchangeRates:
          (json['exchange_rates'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [],
      cashBalances:
          (json['cash_balances'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [],
    );
  }
}

/// Provider for analytics dashboard data
class AnalyticsProvider extends ChangeNotifier {
  final DioClient _dioClient;

  AnalyticsProvider() : _dioClient = sl<DioClient>();

  AnalyticsData? _data;
  bool _isLoading = false;
  String? _errorMessage;

  
  List<Map<String, dynamic>> _cashierStats = [];
  
  List<Map<String, dynamic>> _currencyStats = [];
  
  List<Map<String, dynamic>> _dailyData = [];
  
  List<Map<String, dynamic>> _profitability = [];

  AnalyticsData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get cashierStats => _cashierStats;
  List<Map<String, dynamic>> get currencyStats => _currencyStats;
  List<Map<String, dynamic>> get dailyData => _dailyData;
  List<Map<String, dynamic>> get profitability => _profitability;

  /// Per-currency shift stats
  List<Map<String, dynamic>> _shiftStats = [];
  bool _shiftOpen = false;
  String? _shiftStartedAt;
  
  /// Cash valuation data
  List<Map<String, dynamic>> _cashValuation = [];
  double _totalCashKgs = 0.0;

  List<Map<String, dynamic>> get shiftStats => _shiftStats;
  bool get shiftOpen => _shiftOpen;
  String? get shiftStartedAt => _shiftStartedAt;
  List<Map<String, dynamic>> get cashValuation => _cashValuation;
  double get totalCashKgs => _totalCashKgs;

  /// Load dashboard analytics data
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.analyticsDashboard,
      );
      _data = AnalyticsData.fromJson(response.data as Map<String, dynamic>);
      _errorMessage = null;
    } on DioException catch (e) {
      debugPrint('[Analytics] loadDashboard ERROR (${e.response?.statusCode}): ${e.response?.data}');
      _errorMessage = extractDrfErrorMessage(e, 'Ошибка загрузки аналитики');
    } catch (e) {
      debugPrint('[Analytics] loadDashboard UNEXPECTED ERROR: $e');
      _errorMessage = 'Ошибка загрузки аналитики: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load cash valuation (balance × average rate for each currency)
  Future<void> loadCashValuation() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.cashBalancesAverageRates,
      );
      final data = response.data as Map<String, dynamic>;
      _cashValuation =
          (data['currency_breakdown'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      _totalCashKgs = (data['total_kgs'] as num?)?.toDouble() ?? 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('[Analytics] loadCashValuation ERROR: $e');
    }
  }

  /// Load per-currency shift stats
  Future<void> loadShiftStats() async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.analyticsShiftStats,
      );
      final data = response.data as Map<String, dynamic>;
      _shiftOpen = data['shift_open'] as bool? ?? false;
      _shiftStartedAt = data['shift_started_at'] as String?;
      _shiftStats =
          (data['shift_stats'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      notifyListeners();
    } catch (e) {
      debugPrint('[Analytics] loadShiftStats ERROR: $e');
    }
  }

  /// Load operations analytics (currency popularity + daily data)
  Future<void> loadOperationsAnalytics({int periodDays = 7}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.analyticsOperations,
        queryParameters: {'period': periodDays.toString()},
      );
      final data = response.data as Map<String, dynamic>;
      _currencyStats =
          (data['currency_stats'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      _dailyData =
          (data['daily_data'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading operations analytics: $e');
    }
  }

  /// Load cashier workload analytics
  Future<void> loadCashierLoad({int periodDays = 7}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.analyticsCashierLoad,
        queryParameters: {'period': periodDays.toString()},
      );
      final data = response.data as Map<String, dynamic>;
      _cashierStats =
          (data['cashier_stats'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cashier load: $e');
    }
  }

  /// Load profitability analytics
  Future<void> loadProfitability({int periodDays = 30}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiEndpoints.analyticsProfitability,
        queryParameters: {'period': periodDays.toString()},
      );
      final data = response.data as Map<String, dynamic>;
      _profitability =
          (data['profitability'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profitability: $e');
    }
  }

  /// Load all analytics data
  Future<void> loadAll() async {
    await Future.wait([
      loadDashboard(),
      loadOperationsAnalytics(),
      loadCashierLoad(),
      loadProfitability(),
      loadShiftStats(),
      loadCashValuation(),
    ]);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

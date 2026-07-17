import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/operation.dart';
import '../../domain/repositories/operation_repository.dart';
import '../../di/service_locator.dart';

class OperationProvider extends ChangeNotifier {
  final OperationRepository _repository;

  OperationProvider() : _repository = sl<OperationRepository>();

  List<Operation> _operations = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _todayStats;

  
  String _searchQuery = '';
  String? _operationTypeFilter;
  String? _dateFrom;
  String? _dateTo;
  String? _currencyIdFilter;
  String _ordering = '-created_at';

  
  int _columnsCount = 1; 

  List<Operation> get operations => _operations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get todayStats => _todayStats;

  
  String get searchQuery => _searchQuery;
  String? get operationTypeFilter => _operationTypeFilter;
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  String? get currencyIdFilter => _currencyIdFilter;
  String get ordering => _ordering;
  int get columnsCount => _columnsCount;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _operationTypeFilter != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _currencyIdFilter != null ||
      _ordering != '-created_at';

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadOperations();
  }

  void setOperationTypeFilter(String? type) {
    _operationTypeFilter = type;
    loadOperations();
  }

  void setCurrencyIdFilter(String? currencyId) {
    _currencyIdFilter = currencyId;
    loadOperations();
  }

  void setDateFilter({String? from, String? to}) {
    _dateFrom = from;
    _dateTo = to;
    loadOperations();
  }

  void setOrdering(String ordering) {
    _ordering = ordering;
    loadOperations();
  }

  void clearFilters() {
    _searchQuery = '';
    _operationTypeFilter = null;
    _dateFrom = null;
    _dateTo = null;
    _currencyIdFilter = null;
    _ordering = '-created_at';
    loadOperations();
  }

  /// Load columns count from SharedPreferences
  Future<void> loadColumnsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _columnsCount = prefs.getInt('operations_columns') ?? 1;
    notifyListeners();
  }

  /// Set columns count and persist
  Future<void> setColumnsCount(int count) async {
    if (count < 1 || count > 2) return;
    _columnsCount = count;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('operations_columns', count);
  }

  Future<void> loadOperations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getOperations(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ordering: _ordering,
      operationType: _operationTypeFilter,
      currencyId: _currencyIdFilter,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (operations) {
        _operations = operations;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<Operation?> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    required double totalAmount,
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    debugPrint('[Provider] createOperation started:');
    debugPrint('[Provider]   type=$operationType currencyId=$currencyId rate=$rate amount=$amount total=$totalAmount');
    debugPrint('[Provider]   clientName=$clientName clientCompany=$clientCompany');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createOperation(
      operationType: operationType,
      currencyId: currencyId,
      rate: rate,
      amount: amount,
      totalAmount: totalAmount,
      clientName: clientName,
      clientCompany: clientCompany,
      comment: comment,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        debugPrint('[Provider] createOperation FAILED: ${failure.message} (status: ${failure.statusCode})');
        notifyListeners();
        return null;
      },
      (operation) {
        debugPrint('[Provider] createOperation SUCCESS: id=${operation.id} number=${operation.operationNumber}');
        _operations.insert(0, operation);
        notifyListeners();
        return operation;
      },
    );
  }

  Future<bool> updateOperation({
    required String id,
    required double amount,
    required double rate,
    String? comment,
    String? clientName,
    String? clientCompany,
  }) async {
    debugPrint('[Provider] updateOperation($id) started: rate=$rate amount=$amount');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.updateOperation(
      id: id,
      amount: amount,
      rate: rate,
      comment: comment,
      clientName: clientName,
      clientCompany: clientCompany,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        debugPrint('[Provider] updateOperation FAILED: ${failure.message} (status: ${failure.statusCode})');
        notifyListeners();
        return false;
      },
      (operation) {
        debugPrint('[Provider] updateOperation SUCCESS: id=${operation.id} number=${operation.operationNumber}');
        final index = _operations.indexWhere((o) => o.id == operation.id);
        if (index != -1) {
          _operations[index] = operation;
        }
        notifyListeners();
        return true;
      },
    );
  }

  Future<void> loadTodayStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getTodayStats();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (stats) {
        _todayStats = stats;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> cancelOperation(String id, {double? cancelAmount}) async {
    debugPrint('[Provider] cancelOperation($id) started: cancelAmount=$cancelAmount');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.cancelOperation(
      id: id,
      cancelAmount: cancelAmount,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        debugPrint('[Provider] cancelOperation FAILED: ${failure.message} (status: ${failure.statusCode})');
        notifyListeners();
        return false;
      },
      (operation) {
        debugPrint('[Provider] cancelOperation SUCCESS: id=${operation.id} status=${operation.status}');
        final index = _operations.indexWhere((o) => o.id == operation.id);
        if (index != -1) {
          _operations[index] = operation;
        }
        notifyListeners();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
  }
}

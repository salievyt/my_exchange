import 'package:flutter/foundation.dart';
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

  // Filter state
  String _searchQuery = '';
  String? _operationTypeFilter;
  String? _dateFrom;
  String? _dateTo;
  String _ordering = '-created_at';

  List<Operation> get operations => _operations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get todayStats => _todayStats;

  // Filter getters
  String get searchQuery => _searchQuery;
  String? get operationTypeFilter => _operationTypeFilter;
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  String get ordering => _ordering;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _operationTypeFilter != null ||
      _dateFrom != null ||
      _dateTo != null ||
      _ordering != '-created_at';

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadOperations();
  }

  void setOperationTypeFilter(String? type) {
    _operationTypeFilter = type;
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
    _ordering = '-created_at';
    loadOperations();
  }

  Future<void> loadOperations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getOperations(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ordering: _ordering,
      operationType: _operationTypeFilter,
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
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createOperation(
      operationType: operationType,
      currencyId: currencyId,
      rate: rate,
      amount: amount,
      clientName: clientName,
      clientCompany: clientCompany,
      comment: comment,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return null;
      },
      (operation) {
        _operations.insert(0, operation);
        notifyListeners();
        return operation;
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

  void clearError() {
    _errorMessage = null;
  }
}

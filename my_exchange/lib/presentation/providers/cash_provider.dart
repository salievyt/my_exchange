import 'package:flutter/foundation.dart';
import '../../domain/entities/cash_balance.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/entities/cash_transaction.dart';
import '../../domain/repositories/cash_repository.dart';
import '../../di/service_locator.dart';

class CashProvider extends ChangeNotifier {
  final CashRepository _repository;

  CashProvider() : _repository = sl<CashRepository>();

  List<CashBalance> _balances = [];
  CashRegister? _currentRegister;
  final List<CashTransaction> _transactions = [];
  bool _isLoading = false;
  bool _isRegisterLoading = false;
  String? _errorMessage;

  List<CashBalance> get balances => _balances;
  CashRegister? get currentRegister => _currentRegister;
  List<CashTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isRegisterLoading => _isRegisterLoading;
  String? get errorMessage => _errorMessage;
  bool get isRegisterOpen => _currentRegister?.isOpen ?? false;

  Future<void> loadBalances() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getBalances();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (balances) {
        _balances = balances;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> checkCurrentRegister() async {
    _isRegisterLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getCurrentRegister();

    result.fold(
      (failure) {
        _currentRegister = null;
        _isRegisterLoading = false;
      },
      (register) {
        _currentRegister = register;
        _isRegisterLoading = false;
      },
    );
    notifyListeners();
  }

  Future<bool> openRegister({
    required Map<String, double> openingBalance,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.openRegister(
      openingBalance: openingBalance,
      comment: comment,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (register) {
        _currentRegister = register;
        notifyListeners();
        
        loadBalances();
        checkCurrentRegister();
        return true;
      },
    );
  }

  Future<bool> closeRegister({
    required Map<String, double> closingBalance,
    String? comment,
  }) async {
    if (_currentRegister == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.closeRegister(
      id: _currentRegister!.id,
      closingBalance: closingBalance,
      comment: comment,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (register) {
        _currentRegister = register;
        notifyListeners();
        
        loadBalances();
        checkCurrentRegister();
        return true;
      },
    );
  }

  Future<bool> createTransaction({
    required String transactionType,
    required int currencyId,
    required double amount,
    String? clientName,
    String? clientCompany,
    double? rate,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createTransaction(
      transactionType: transactionType,
      currencyId: currencyId,
      amount: amount,
      clientName: clientName,
      clientCompany: clientCompany,
      rate: rate,
      comment: comment,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (transaction) {
        _transactions.insert(0, transaction);
        notifyListeners();
        
        loadBalances();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
  }
}

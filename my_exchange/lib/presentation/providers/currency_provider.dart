import 'package:flutter/foundation.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../di/service_locator.dart';

class CurrencyProvider extends ChangeNotifier {
  final CurrencyRepository _repository;

  CurrencyProvider() : _repository = sl<CurrencyRepository>();

  List<Currency> _currencies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Currency> get currencies => _currencies;

  /// Currencies excluding the base currency (KGS).
  List<Currency> get foreignCurrencies =>
      _currencies.where((c) => !c.isBaseCurrency).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCurrencies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getActiveCurrencies();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (currencies) {
        _currencies = currencies;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Currency? getCurrencyById(int id) {
    try {
      return _currencies.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateCurrency({
    required int id,
    String? code,
    String? name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool? isActive,
  }) async {
    final result = await _repository.updateCurrency(
      id: id,
      code: code,
      name: name,
      symbol: symbol,
      buyRate: buyRate,
      sellRate: sellRate,
      isActive: isActive,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (currency) {
        final index = _currencies.indexWhere((c) => c.id == currency.id);
        if (index != -1) {
          _currencies[index] = currency;
        }
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> createCurrency({
    required String code,
    required String name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool isActive = true,
  }) async {
    final result = await _repository.createCurrency(
      code: code,
      name: name,
      symbol: symbol ?? code,
      buyRate: buyRate,
      sellRate: sellRate,
      isActive: isActive,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (currency) {
        _currencies.add(currency);
        _errorMessage = null;
        notifyListeners();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
  }
}

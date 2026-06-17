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

  void clearError() {
    _errorMessage = null;
  }
}

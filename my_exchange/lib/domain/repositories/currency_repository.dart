import 'package:dartz/dartz.dart';
import '../entities/currency.dart';
import '../../core/errors/failures.dart';

/// Currency repository interface
abstract class CurrencyRepository {
  Future<Either<Failure, List<Currency>>> getCurrencies({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<Either<Failure, List<Currency>>> getActiveCurrencies();

  Future<Either<Failure, Currency>> getCurrencyById(int id);

  Future<Either<Failure, Currency>> createCurrency({
    required String code,
    required String name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool isActive = true,
  });

  Future<Either<Failure, Currency>> updateCurrency({
    required int id,
    String? code,
    String? name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool? isActive,
  });

  Future<Either<Failure, void>> deleteCurrency(int id);

  Future<Either<Failure, List<Map<String, dynamic>>>> getCurrencyHistory(
    int id,
  );
}

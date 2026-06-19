import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/currency.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/currency_remote_datasource.dart';

/// Currency repository implementation
class CurrencyRepositoryImpl implements CurrencyRepository {
  final CurrencyRemoteDataSource remoteDataSource;

  CurrencyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Currency>>> getCurrencies({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final currencies = await remoteDataSource.getCurrencies(
        page: page,
        pageSize: pageSize,
        search: search,
        ordering: ordering,
      );
      return Right(currencies.map((c) => c.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Currency>>> getActiveCurrencies() async {
    try {
      final currencies = await remoteDataSource.getActiveCurrencies();
      return Right(currencies.map((c) => c.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Currency>> getCurrencyById(int id) async {
    try {
      final currency = await remoteDataSource.getCurrencyById(id);
      return Right(currency.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Currency>> createCurrency({
    required String code,
    required String name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool isActive = true,
  }) async {
    try {
      final currency = await remoteDataSource.createCurrency(
        code: code,
        name: name,
        symbol: symbol,
        buyRate: buyRate,
        sellRate: sellRate,
        isActive: isActive,
      );
      return Right(currency.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Currency>> updateCurrency({
    required int id,
    String? code,
    String? name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool? isActive,
  }) async {
    try {
      final currency = await remoteDataSource.updateCurrency(
        id: id,
        code: code,
        name: name,
        symbol: symbol,
        buyRate: buyRate,
        sellRate: sellRate,
        isActive: isActive,
      );
      return Right(currency.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCurrency(int id) async {
    try {
      await remoteDataSource.deleteCurrency(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCurrencyHistory(
    int id,
  ) async {
    try {
      final history = await remoteDataSource.getCurrencyHistory(id);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

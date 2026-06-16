import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cash_balance.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/entities/cash_transaction.dart';
import '../../domain/repositories/cash_repository.dart';
import '../datasources/cash_remote_datasource.dart';

/// Cash repository implementation
class CashRepositoryImpl implements CashRepository {
  final CashRemoteDataSource remoteDataSource;

  CashRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CashBalance>>> getBalances({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final balances = await remoteDataSource.getBalances(
        page: page,
        pageSize: pageSize,
        search: search,
        ordering: ordering,
      );
      return Right(balances.map((b) => b.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashBalance>> getBalanceById(int id) async {
    try {
      final balance = await remoteDataSource.getBalanceById(id);
      return Right(balance.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBalanceSummary() async {
    try {
      final summary = await remoteDataSource.getBalanceSummary();
      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<CashBalance>>> getLowBalances() async {
    try {
      final balances = await remoteDataSource.getLowBalances();
      return Right(balances.map((b) => b.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<CashRegister>>> getRegisters({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final registers = await remoteDataSource.getRegisters(
        page: page,
        pageSize: pageSize,
        search: search,
        ordering: ordering,
      );
      return Right(registers.map((r) => r.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> getRegisterById(String id) async {
    try {
      final register = await remoteDataSource.getRegisterById(id);
      return Right(register.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> getCurrentRegister() async {
    try {
      final register = await remoteDataSource.getCurrentRegister();
      return Right(register.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> openRegister({
    required Map<String, double> openingBalance,
    String? comment,
  }) async {
    try {
      final register = await remoteDataSource.openRegister(
        openingBalance: openingBalance,
        comment: comment,
      );
      return Right(register.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> closeRegister({
    required String id,
    required Map<String, double> closingBalance,
    String? comment,
  }) async {
    try {
      final register = await remoteDataSource.closeRegister(
        id: id,
        closingBalance: closingBalance,
        comment: comment,
      );
      return Right(register.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashRegister>> updateRegister({
    required String id,
    String? comment,
  }) async {
    try {
      final register = await remoteDataSource.updateRegister(
        id: id,
        comment: comment,
      );
      return Right(register.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<CashTransaction>>> getTransactions({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactions(
        page: page,
        pageSize: pageSize,
        search: search,
        ordering: ordering,
      );
      return Right(transactions.map((t) => t.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashTransaction>> getTransactionById(String id) async {
    try {
      final transaction = await remoteDataSource.getTransactionById(id);
      return Right(transaction.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, CashTransaction>> createTransaction({
    required String transactionType,
    required int currencyId,
    required double amount,
    String? comment,
  }) async {
    try {
      final transaction = await remoteDataSource.createTransaction(
        transactionType: transactionType,
        currencyId: currencyId,
        amount: amount,
        comment: comment,
      );
      return Right(transaction.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await remoteDataSource.deleteTransaction(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

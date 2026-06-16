import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/operation.dart';
import '../../domain/repositories/operation_repository.dart';
import '../datasources/operation_remote_datasource.dart';

/// Operation repository implementation
class OperationRepositoryImpl implements OperationRepository {
  final OperationRemoteDataSource remoteDataSource;

  OperationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Operation>>> getOperations({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final operations = await remoteDataSource.getOperations(
        page: page,
        pageSize: pageSize,
        search: search,
        ordering: ordering,
      );
      return Right(operations.map((o) => o.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Operation>> getOperationById(String id) async {
    try {
      final operation = await remoteDataSource.getOperationById(id);
      return Right(operation.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Operation>> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    try {
      final operation = await remoteDataSource.createOperation(
        operationType: operationType,
        currencyId: currencyId,
        rate: rate,
        amount: amount,
        clientName: clientName,
        clientCompany: clientCompany,
        comment: comment,
      );
      return Right(operation.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Operation>> updateOperation({
    required String id,
    required double amount,
    required double rate,
    String? comment,
    String? clientName,
    String? clientCompany,
  }) async {
    try {
      final operation = await remoteDataSource.updateOperation(
        id: id,
        amount: amount,
        rate: rate,
        comment: comment,
        clientName: clientName,
        clientCompany: clientCompany,
      );
      return Right(operation.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOperation(String id) async {
    try {
      await remoteDataSource.deleteOperation(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Operation>> cancelOperation({
    required String id,
    double? cancelAmount,
  }) async {
    try {
      final operation = await remoteDataSource.cancelOperation(
        id: id,
        cancelAmount: cancelAmount,
      );
      return Right(operation.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getOperationHistory(
    String id,
  ) async {
    try {
      final history = await remoteDataSource.getOperationHistory(id);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTodayStats() async {
    try {
      final stats = await remoteDataSource.getTodayStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

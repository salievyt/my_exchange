import 'package:dartz/dartz.dart';
import '../entities/operation.dart';
import '../../core/errors/failures.dart';

/// Operation repository interface
abstract class OperationRepository {
  Future<Either<Failure, List<Operation>>> getOperations({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
    String? operationType,
    String? currencyId,
    String? dateFrom,
    String? dateTo,
  });

  Future<Either<Failure, Operation>> getOperationById(String id);

  Future<Either<Failure, Operation>> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    String? clientName,
    String? clientCompany,
    String? comment,
  });

  Future<Either<Failure, Operation>> updateOperation({
    required String id,
    required double amount,
    required double rate,
    String? comment,
    String? clientName,
    String? clientCompany,
  });

  Future<Either<Failure, void>> deleteOperation(String id);

  Future<Either<Failure, Operation>> cancelOperation({
    required String id,
    double? cancelAmount,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getOperationHistory(
    String id,
  );

  Future<Either<Failure, Map<String, dynamic>>> getTodayStats();
}

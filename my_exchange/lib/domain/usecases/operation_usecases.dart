import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/operation.dart';
import '../repositories/operation_repository.dart';

/// Get operations use case
class GetOperationsUseCase {
  final OperationRepository repository;

  GetOperationsUseCase(this.repository);

  Future<Either<Failure, List<Operation>>> call({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    return await repository.getOperations(
      page: page,
      pageSize: pageSize,
      search: search,
      ordering: ordering,
    );
  }
}

/// Create operation use case
class CreateOperationUseCase {
  final OperationRepository repository;

  CreateOperationUseCase(this.repository);

  Future<Either<Failure, Operation>> call({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    return await repository.createOperation(
      operationType: operationType,
      currencyId: currencyId,
      rate: rate,
      amount: amount,
      clientName: clientName,
      clientCompany: clientCompany,
      comment: comment,
    );
  }
}

/// Get today stats use case
class GetTodayStatsUseCase {
  final OperationRepository repository;

  GetTodayStatsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() async {
    return await repository.getTodayStats();
  }
}

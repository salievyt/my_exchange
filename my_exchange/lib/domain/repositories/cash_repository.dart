import 'package:dartz/dartz.dart';
import '../entities/cash_balance.dart';
import '../entities/cash_transaction.dart';
import '../entities/cash_register.dart';
import '../../core/errors/failures.dart';

/// Cash repository interface
abstract class CashRepository {
  // Balances
  Future<Either<Failure, List<CashBalance>>> getBalances({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<Either<Failure, CashBalance>> getBalanceById(int id);

  Future<Either<Failure, Map<String, dynamic>>> getBalanceSummary();

  Future<Either<Failure, List<CashBalance>>> getLowBalances();

  // Registers
  Future<Either<Failure, List<CashRegister>>> getRegisters({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<Either<Failure, CashRegister>> getRegisterById(String id);

  Future<Either<Failure, CashRegister>> getCurrentRegister();

  Future<Either<Failure, CashRegister>> openRegister({
    required Map<String, double> openingBalance,
    String? comment,
  });

  Future<Either<Failure, CashRegister>> closeRegister({
    required String id,
    required Map<String, double> closingBalance,
    String? comment,
  });

  Future<Either<Failure, CashRegister>> updateRegister({
    required String id,
    String? comment,
  });

  // Transactions
  Future<Either<Failure, List<CashTransaction>>> getTransactions({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<Either<Failure, CashTransaction>> getTransactionById(String id);

  Future<Either<Failure, CashTransaction>> createTransaction({
    required String transactionType,
    required int currencyId,
    required double amount,
    String? comment,
  });

  Future<Either<Failure, void>> deleteTransaction(String id);
}

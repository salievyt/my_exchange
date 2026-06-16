import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType {
  deposit('deposit', 'Внесение наличности'),
  withdrawal('withdrawal', 'Выдача наличности'),
  inkassation('inkassation', 'Инкассация');

  final String value;
  final String displayName;

  const TransactionType(this.value, this.displayName);

  factory TransactionType.fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.deposit,
    );
  }
}

/// Cash transaction entity
class CashTransaction extends Equatable {
  final int id;
  final TransactionType transactionType;
  final int currencyId;
  final String currencyCode;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final int cashierId;
  final String cashierUsername;
  final String cashierName;
  final String? comment;
  final DateTime createdAt;

  const CashTransaction({
    required this.id,
    required this.transactionType,
    required this.currencyId,
    required this.currencyCode,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.cashierId,
    required this.cashierUsername,
    required this.cashierName,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    transactionType,
    currencyId,
    currencyCode,
    amount,
    balanceBefore,
    balanceAfter,
    cashierId,
    cashierUsername,
    cashierName,
    comment,
    createdAt,
  ];
}

import 'package:equatable/equatable.dart';

/// Cash register entity
class CashRegister extends Equatable {
  final int id;
  final int cashierId;
  final String cashierUsername;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final bool isOpen;
  final Map<String, double>? openingBalance;
  final Map<String, double>? closingBalance;
  final String? comment;

  const CashRegister({
    required this.id,
    required this.cashierId,
    required this.cashierUsername,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.isOpen,
    this.openingBalance,
    this.closingBalance,
    this.comment,
  });

  bool get isClosed => !isOpen;

  @override
  List<Object?> get props => [
    id,
    cashierId,
    cashierUsername,
    cashierName,
    openedAt,
    closedAt,
    isOpen,
    openingBalance,
    closingBalance,
    comment,
  ];
}

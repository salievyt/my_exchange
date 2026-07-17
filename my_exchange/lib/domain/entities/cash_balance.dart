import 'package:equatable/equatable.dart';

/// Cash balance entity
class CashBalance extends Equatable {
  final int id;
  final int currencyId;
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;
  final double balance;
  final double balanceFromOperations;
  final double reserved;
  final double availableBalance;
  final DateTime lastUpdated;

  const CashBalance({
    required this.id,
    required this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.balance,
    this.balanceFromOperations = 0.0,
    required this.reserved,
    required this.availableBalance,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    id,
    currencyId,
    currencyCode,
    currencyName,
    currencySymbol,
    balance,
    balanceFromOperations,
    reserved,
    availableBalance,
    lastUpdated,
  ];
}

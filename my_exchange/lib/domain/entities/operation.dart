import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

/// Operation type enum
enum OperationType {
  buy('buy', 'Покупка валюты'),
  sell('sell', 'Продажа валюты');

  final String value;
  final String displayName;

  const OperationType(this.value, this.displayName);

  factory OperationType.fromString(String value) {
    return OperationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OperationType.buy,
    );
  }
}

/// Operation status enum
enum OperationStatus {
  @JsonValue('active')
  active('active', 'Активна'),
  @JsonValue('cancelled')
  cancelled('cancelled', 'Отменена'),
  @JsonValue('partially_cancelled')
  partiallyCancelled('partially_cancelled', 'Частично отменена');

  final String value;
  final String displayName;

  const OperationStatus(this.value, this.displayName);

  factory OperationStatus.fromString(String value) {
    return OperationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OperationStatus.active,
    );
  }
}

/// Operation entity
class Operation extends Equatable {
  final int id;
  final String operationNumber;
  final OperationType operationType;
  final OperationStatus status;
  final String? clientName;
  final String? clientCompany;
  final int currencyId;
  final String currencyCode;
  final String currencyName;
  final double rate;
  final double amount;
  final double totalAmount;
  final int cashierId;
  final String cashierUsername;
  final String cashierName;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Operation({
    required this.id,
    required this.operationNumber,
    required this.operationType,
    required this.status,
    this.clientName,
    this.clientCompany,
    required this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.rate,
    required this.amount,
    required this.totalAmount,
    required this.cashierId,
    required this.cashierUsername,
    required this.cashierName,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCancelled => status == OperationStatus.cancelled;
  bool get isPartiallyCancelled => status == OperationStatus.partiallyCancelled;
  bool get canBeCancelled => status == OperationStatus.active;

  @override
  List<Object?> get props => [
    id,
    operationNumber,
    operationType,
    status,
    clientName,
    clientCompany,
    currencyId,
    currencyCode,
    currencyName,
    rate,
    amount,
    totalAmount,
    cashierId,
    cashierUsername,
    cashierName,
    comment,
    createdAt,
    updatedAt,
  ];
}

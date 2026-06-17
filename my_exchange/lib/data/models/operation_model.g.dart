// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperationModel _$OperationModelFromJson(Map<String, dynamic> json) =>
    OperationModel(
      id: jsonInt(json['id']),
      operationNumber: json['operation_number'] as String? ?? '',
      operationType: $enumDecodeNullable(
        _$OperationTypeEnumMap,
        json['operation_type'],
      ) ?? OperationType.buy,
      status: $enumDecodeNullable(
        _$OperationStatusEnumMap,
        json['status'],
      ) ?? OperationStatus.active,
      clientName: json['client_name'] as String?,
      clientCompany: json['client_company'] as String?,
      currencyId: jsonInt(json['currency']),
      currencyCode: json['currency_code'] as String? ?? '',
      currencyName: json['currency_name'] as String? ?? '',
      rate: jsonDouble(json['rate']),
      amount: jsonDouble(json['amount']),
      totalAmount: jsonDouble(json['total_amount']),
      cashierId: jsonInt(json['cashier']),
      cashierUsername: json['cashier_username'] as String? ?? '',
      cashierName: json['cashier_name'] as String? ?? '',
      comment: json['comment'] as String?,
      createdAt: jsonDateTime(json['created_at']),
      updatedAt: jsonDateTime(json['updated_at']),
    );

Map<String, dynamic> _$OperationModelToJson(OperationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operation_number': instance.operationNumber,
      'operation_type': _$OperationTypeEnumMap[instance.operationType]!,
      'status': _$OperationStatusEnumMap[instance.status]!,
      'client_name': instance.clientName,
      'client_company': instance.clientCompany,
      'currency': instance.currencyId,
      'currency_code': instance.currencyCode,
      'currency_name': instance.currencyName,
      'rate': instance.rate,
      'amount': instance.amount,
      'total_amount': instance.totalAmount,
      'cashier': instance.cashierId,
      'cashier_username': instance.cashierUsername,
      'cashier_name': instance.cashierName,
      'comment': instance.comment,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$OperationTypeEnumMap = {
  OperationType.buy: 'buy',
  OperationType.sell: 'sell',
};

const _$OperationStatusEnumMap = {
  OperationStatus.active: 'active',
  OperationStatus.cancelled: 'cancelled',
  OperationStatus.partiallyCancelled: 'partially_cancelled',
};

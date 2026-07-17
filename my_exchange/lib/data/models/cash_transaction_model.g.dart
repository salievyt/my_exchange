// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashTransactionModel _$CashTransactionModelFromJson(
  Map<String, dynamic> json,
) => CashTransactionModel(
  id: (json['id'] as num).toInt(),
  transactionType: $enumDecode(
    _$TransactionTypeEnumMap,
    json['transaction_type'],
  ),
  currencyId: (json['currency'] as num).toInt(),
  currencyCode: json['currency_code'] as String,
  amount: (json['amount'] as num).toDouble(),
  balanceBefore: (json['balance_before'] as num).toDouble(),
  balanceAfter: (json['balance_after'] as num).toDouble(),
  cashierId: (json['cashier'] as num).toInt(),
  cashierUsername: json['cashier_username'] as String,
  cashierName: json['cashier_name'] as String,
  clientName: json['client_name'] as String?,
  clientCompany: json['client_company'] as String?,
  rate: (json['rate'] as num?)?.toDouble(),
  comment: json['comment'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CashTransactionModelToJson(
  CashTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'transaction_type': _$TransactionTypeEnumMap[instance.transactionType]!,
  'currency': instance.currencyId,
  'currency_code': instance.currencyCode,
  'amount': instance.amount,
  'balance_before': instance.balanceBefore,
  'balance_after': instance.balanceAfter,
  'cashier': instance.cashierId,
  'cashier_username': instance.cashierUsername,
  'cashier_name': instance.cashierName,
  'client_name': instance.clientName,
  'client_company': instance.clientCompany,
  'rate': instance.rate,
  'comment': instance.comment,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$TransactionTypeEnumMap = {
  TransactionType.deposit: 'deposit',
  TransactionType.withdrawal: 'withdrawal',
  TransactionType.inkassation: 'inkassation',
};

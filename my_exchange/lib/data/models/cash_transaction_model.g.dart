// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashTransactionModel _$CashTransactionModelFromJson(
  Map<String, dynamic> json,
) => CashTransactionModel(
  id: jsonInt(json['id']),
  transactionType: $enumDecodeNullable(
    _$TransactionTypeEnumMap,
    json['transaction_type'],
  ) ?? TransactionType.deposit,
  currencyId: jsonInt(json['currency']),
  currencyCode: json['currency_code'] as String? ?? '',
  amount: jsonDouble(json['amount']),
  balanceBefore: jsonDouble(json['balance_before']),
  balanceAfter: jsonDouble(json['balance_after']),
  cashierId: jsonInt(json['cashier']),
  cashierUsername: json['cashier_username'] as String? ?? '',
  cashierName: json['cashier_name'] as String? ?? '',
  comment: json['comment'] as String?,
  createdAt: jsonDateTime(json['created_at']),
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
  'comment': instance.comment,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$TransactionTypeEnumMap = {
  TransactionType.deposit: 'deposit',
  TransactionType.withdrawal: 'withdrawal',
  TransactionType.inkassation: 'inkassation',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashBalanceModel _$CashBalanceModelFromJson(Map<String, dynamic> json) =>
    CashBalanceModel(
      id: (json['id'] as num).toInt(),
      currencyId: (json['currency'] as num).toInt(),
      currencyCode: json['currency_code'] as String,
      currencyName: json['currency_name'] as String,
      currencySymbol: json['currency_symbol'] as String,
      balance: (json['balance'] as num).toDouble(),
      reserved: (json['reserved'] as num).toDouble(),
      availableBalance: (json['available_balance'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );

Map<String, dynamic> _$CashBalanceModelToJson(CashBalanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currency': instance.currencyId,
      'currency_code': instance.currencyCode,
      'currency_name': instance.currencyName,
      'currency_symbol': instance.currencySymbol,
      'balance': instance.balance,
      'reserved': instance.reserved,
      'available_balance': instance.availableBalance,
      'last_updated': instance.lastUpdated.toIso8601String(),
    };

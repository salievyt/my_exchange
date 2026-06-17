// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashRegisterModel _$CashRegisterModelFromJson(Map<String, dynamic> json) =>
    CashRegisterModel(
      id: jsonInt(json['id']),
      cashierId: jsonInt(json['cashier']),
      cashierUsername: json['cashier_username'] as String? ?? '',
      cashierName: json['cashier_name'] as String? ?? '',
      openedAt: jsonDateTime(json['opened_at']),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      isOpen: json['is_open'] == true,
      openingBalance: _parseBalanceMap(json['opening_balance']),
      closingBalance: _parseBalanceMap(json['closing_balance']),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$CashRegisterModelToJson(CashRegisterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cashier': instance.cashierId,
      'cashier_username': instance.cashierUsername,
      'cashier_name': instance.cashierName,
      'opened_at': instance.openedAt.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
      'is_open': instance.isOpen,
      'comment': instance.comment,
      'opening_balance': _encodeBalanceMap(instance.openingBalance),
      'closing_balance': _encodeBalanceMap(instance.closingBalance),
    };

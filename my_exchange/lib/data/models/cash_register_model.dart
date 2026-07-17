import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/cash_register.dart';

part 'cash_register_model.g.dart';

Map<String, double>? _parseBalanceMap(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }
  if (value is String && value.isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
  }
  return null;
}

dynamic _encodeBalanceMap(Map<String, double>? map) {
  return map;
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CashRegisterModel extends CashRegister {
  const CashRegisterModel({
    required super.id,
    @JsonKey(name: 'cashier') required super.cashierId,
    required super.cashierUsername,
    required super.cashierName,
    required super.openedAt,
    super.closedAt,
    required super.isOpen,
    super.openingBalance,
    super.closingBalance,
    super.comment,
  });

  @JsonKey(fromJson: _parseBalanceMap, toJson: _encodeBalanceMap)
  @override
  Map<String, double>? get openingBalance => super.openingBalance;

  @JsonKey(fromJson: _parseBalanceMap, toJson: _encodeBalanceMap)
  @override
  Map<String, double>? get closingBalance => super.closingBalance;

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) =>
      _$CashRegisterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashRegisterModelToJson(this);

  CashRegister toEntity() => CashRegister(
    id: id,
    cashierId: cashierId,
    cashierUsername: cashierUsername,
    cashierName: cashierName,
    openedAt: openedAt,
    closedAt: closedAt,
    isOpen: isOpen,
    openingBalance: openingBalance,
    closingBalance: closingBalance,
    comment: comment,
  );
}

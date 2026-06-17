import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/json_helpers.dart';
import '../../domain/entities/cash_balance.dart';

part 'cash_balance_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CashBalanceModel extends CashBalance {
  const CashBalanceModel({
    required super.id,
    @JsonKey(name: 'currency') required super.currencyId,
    required super.currencyCode,
    required super.currencyName,
    required super.currencySymbol,
    required super.balance,
    required super.reserved,
    required super.availableBalance,
    required super.lastUpdated,
  });

  factory CashBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$CashBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashBalanceModelToJson(this);

  CashBalance toEntity() => CashBalance(
    id: id,
    currencyId: currencyId,
    currencyCode: currencyCode,
    currencyName: currencyName,
    currencySymbol: currencySymbol,
    balance: balance,
    reserved: reserved,
    availableBalance: availableBalance,
    lastUpdated: lastUpdated,
  );
}

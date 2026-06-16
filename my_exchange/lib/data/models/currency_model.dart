import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/currency.dart';

part 'currency_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CurrencyModel extends Currency {
  const CurrencyModel({
    required super.id,
    required super.code,
    required super.name,
    required super.symbol,
    required super.isActive,
    super.buyRate,
    super.sellRate,
    super.createdAt,
    super.updatedAt,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyModelFromJson(json);

  Map<String, dynamic> toJson() => _$CurrencyModelToJson(this);

  factory CurrencyModel.fromEntity(Currency currency) => CurrencyModel(
    id: currency.id,
    code: currency.code,
    name: currency.name,
    symbol: currency.symbol,
    isActive: currency.isActive,
    buyRate: currency.buyRate,
    sellRate: currency.sellRate,
    createdAt: currency.createdAt,
    updatedAt: currency.updatedAt,
  );

  Currency toEntity() => Currency(
    id: id,
    code: code,
    name: name,
    symbol: symbol,
    isActive: isActive,
    buyRate: buyRate,
    sellRate: sellRate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

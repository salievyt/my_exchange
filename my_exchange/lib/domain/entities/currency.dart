import 'package:equatable/equatable.dart';

/// Currency entity
class Currency extends Equatable {
  final int id;
  final String code;
  final String name;
  final String symbol;
  final bool isActive;
  final double? buyRate;
  final double? sellRate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.isActive,
    this.buyRate,
    this.sellRate,
    this.createdAt,
    this.updatedAt,
  });

  bool get isBaseCurrency => code == 'KGS';

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    symbol,
    isActive,
    buyRate,
    sellRate,
  ];

  @override
  String toString() => 'Currency(id: $id, code: $code, name: $name)';
}

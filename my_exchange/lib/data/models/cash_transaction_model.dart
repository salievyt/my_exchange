import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/json_helpers.dart';
import '../../domain/entities/cash_transaction.dart';

part 'cash_transaction_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CashTransactionModel extends CashTransaction {
  const CashTransactionModel({
    required super.id,
    required super.transactionType,
    @JsonKey(name: 'currency') required super.currencyId,
    required super.currencyCode,
    required super.amount,
    required super.balanceBefore,
    required super.balanceAfter,
    @JsonKey(name: 'cashier') required super.cashierId,
    required super.cashierUsername,
    required super.cashierName,
    super.comment,
    required super.createdAt,
  });

  factory CashTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$CashTransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashTransactionModelToJson(this);

  CashTransaction toEntity() => CashTransaction(
    id: id,
    transactionType: transactionType,
    currencyId: currencyId,
    currencyCode: currencyCode,
    amount: amount,
    balanceBefore: balanceBefore,
    balanceAfter: balanceAfter,
    cashierId: cashierId,
    cashierUsername: cashierUsername,
    cashierName: cashierName,
    comment: comment,
    createdAt: createdAt,
  );
}

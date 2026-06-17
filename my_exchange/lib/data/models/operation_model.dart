import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/json_helpers.dart';
import '../../domain/entities/operation.dart';

part 'operation_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OperationModel extends Operation {
  const OperationModel({
    required super.id,
    required super.operationNumber,
    required super.operationType,
    required super.status,
    super.clientName,
    super.clientCompany,
    @JsonKey(name: 'currency') required super.currencyId,
    required super.currencyCode,
    required super.currencyName,
    required super.rate,
    required super.amount,
    required super.totalAmount,
    @JsonKey(name: 'cashier') required super.cashierId,
    required super.cashierUsername,
    required super.cashierName,
    super.comment,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OperationModel.fromJson(Map<String, dynamic> json) =>
      _$OperationModelFromJson(json);

  Map<String, dynamic> toJson() => _$OperationModelToJson(this);

  factory OperationModel.fromEntity(Operation operation) => OperationModel(
    id: operation.id,
    operationNumber: operation.operationNumber,
    operationType: operation.operationType,
    status: operation.status,
    clientName: operation.clientName,
    clientCompany: operation.clientCompany,
    currencyId: operation.currencyId,
    currencyCode: operation.currencyCode,
    currencyName: operation.currencyName,
    rate: operation.rate,
    amount: operation.amount,
    totalAmount: operation.totalAmount,
    cashierId: operation.cashierId,
    cashierUsername: operation.cashierUsername,
    cashierName: operation.cashierName,
    comment: operation.comment,
    createdAt: operation.createdAt,
    updatedAt: operation.updatedAt,
  );

  Operation toEntity() => Operation(
    id: id,
    operationNumber: operationNumber,
    operationType: operationType,
    status: status,
    clientName: clientName,
    clientCompany: clientCompany,
    currencyId: currencyId,
    currencyCode: currencyCode,
    currencyName: currencyName,
    rate: rate,
    amount: amount,
    totalAmount: totalAmount,
    cashierId: cashierId,
    cashierUsername: cashierUsername,
    cashierName: cashierName,
    comment: comment,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

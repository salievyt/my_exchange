import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/json_helpers.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    super.firstName,
    super.lastName,
    required super.role,
    super.phone,
    required super.isTwoFactorEnabled,
    required super.createdAt,
    required super.updatedAt,
    required super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromEntity(User user) => UserModel(
    id: user.id,
    username: user.username,
    email: user.email,
    firstName: user.firstName,
    lastName: user.lastName,
    role: user.role,
    phone: user.phone,
    isTwoFactorEnabled: user.isTwoFactorEnabled,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    isActive: user.isActive,
  );

  User toEntity() => User(
    id: id,
    username: username,
    email: email,
    firstName: firstName,
    lastName: lastName,
    role: role,
    phone: phone,
    isTwoFactorEnabled: isTwoFactorEnabled,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isActive: isActive,
  );
}

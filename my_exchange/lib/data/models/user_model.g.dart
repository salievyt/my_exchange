// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: jsonInt(json['id']),
  username: json['username'] as String? ?? '',
  email: json['email'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  role: $enumDecodeNullable(
    _$UserRoleEnumMap,
    json['role'],
  ) ?? UserRole.cashier,
  phone: json['phone'] as String?,
  isTwoFactorEnabled: json['is_two_factor_enabled'] == true,
  createdAt: jsonDateTime(json['created_at']),
  updatedAt: jsonDateTime(json['updated_at']),
  isActive: json['is_active'] == true,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'role': _$UserRoleEnumMap[instance.role]!,
  'phone': instance.phone,
  'is_two_factor_enabled': instance.isTwoFactorEnabled,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'is_active': instance.isActive,
};

const _$UserRoleEnumMap = {
  UserRole.cashier: 'cashier',
  UserRole.seniorCashier: 'senior_cashier',
  UserRole.admin: 'admin',
};

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

/// User role enum
enum UserRole {
  @JsonValue('cashier')
  cashier('cashier', 'Кассир'),

  @JsonValue('senior_cashier')
  seniorCashier('senior_cashier', 'Старший кассир'),

  @JsonValue('admin')
  admin('admin', 'Администратор');

  final String value;
  final String displayName;

  const UserRole(this.value, this.displayName);

  factory UserRole.fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.cashier,
    );
  }
}

/// User entity
class User extends Equatable {
  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final UserRole role;
  final String? phone;
  final bool isTwoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.phone,
    required this.isTwoFactorEnabled,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isSeniorCashier => role == UserRole.seniorCashier;
  bool get isCashier => role == UserRole.cashier;

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    role,
    phone,
    isTwoFactorEnabled,
    createdAt,
    updatedAt,
    isActive,
  ];

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}

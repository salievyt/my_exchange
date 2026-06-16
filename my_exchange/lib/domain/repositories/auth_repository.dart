import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../../core/errors/failures.dart';

/// Auth repository interface
abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, User>> refreshToken(String refreshToken);

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, bool>> isAuthenticated();
}

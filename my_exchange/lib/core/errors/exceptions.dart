/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode});
}

/// Server exception
class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

/// Network exception
class NetworkException extends AppException {
  const NetworkException({required super.message});
}

/// Cache exception
class CacheException extends AppException {
  const CacheException({required super.message});
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException({required super.message});
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException({required super.message});
}

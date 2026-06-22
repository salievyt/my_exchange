import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Auth remote data source
abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String username, required String password});

  Future<UserModel> refreshToken(String refreshToken);

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearTokens();

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();
}

/// Auth remote data source implementation
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  AuthRemoteDataSourceImpl({
    required this.dioClient,
    required this.secureStorage,
  });

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = _asMap(response.data);
      final accessToken = data['access'] as String;
      final refreshToken = data['refresh'] as String;

      await saveTokens(accessToken: accessToken, refreshToken: refreshToken);

      final userData = data['user'];
      if (userData is Map<String, dynamic>) {
        return UserModel.fromJson(userData);
      }

      final userResponse = await dioClient.dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(_asMap(userResponse.data));
    } on DioException catch (e) {
      throw AuthException(
        message: _errorMessage(e.response?.data, fallback: 'Ошибка авторизации'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthException(message: 'Ошибка авторизации: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final accessToken = response.data['access'] as String;
      await secureStorage.write(
        key: StorageKeys.accessToken,
        value: accessToken,
      );

      final userResponse = await dioClient.dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(_asMap(userResponse.data));
    } on DioException catch (e) {
      await clearTokens();
      throw AuthException(
        message: 'Токен истек',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post(ApiEndpoints.logout);
    } catch (e) {
      
    } finally {
      await clearTokens();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.usersMe);
      return UserModel.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw AuthException(
        message: 'Ошибка получения данных пользователя',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dioClient.dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw AuthException(
        message: _errorMessage(e.response?.data, fallback: 'Ошибка смены пароля'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await secureStorage.write(key: StorageKeys.accessToken, value: accessToken);
    await secureStorage.write(
      key: StorageKeys.refreshToken,
      value: refreshToken,
    );
  }

  @override
  Future<void> clearTokens() async {
    await secureStorage.delete(key: StorageKeys.accessToken);
    await secureStorage.delete(key: StorageKeys.refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: StorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: StorageKeys.refreshToken);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException('Некорректный формат ответа сервера');
  }

  String _errorMessage(dynamic data, {required String fallback}) {
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    if (data is List && data.isNotEmpty) {
      return data.join(', ');
    }
    if (data is Map) {
      final detail = data['detail'];
      if (detail != null) {
        return detail.toString();
      }

      final nonFieldErrors = data['non_field_errors'];
      if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
        return nonFieldErrors.join(', ');
      }
      if (nonFieldErrors != null) {
        return nonFieldErrors.toString();
      }

      if (data.isNotEmpty) {
        return data.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
      }
    }
    return fallback;
  }
}

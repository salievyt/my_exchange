import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_exchange/core/constants/api_constants.dart';

/// Network information provider
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Network info implementation
class NetworkInfoImpl implements NetworkInfo {
  // In a real app, use connectivity_plus package
  @override
  Future<bool> get isConnected async {
    // Placeholder - implement with connectivity_plus
    return true;
  }
}

/// Dio client wrapper
class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient(this._dio, this._secureStorage) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }

          // Add auth token to headers
          final accessToken = await _secureStorage.read(
            key: StorageKeys.accessToken,
          );
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (error.requestOptions.extra['skipAuth'] == true) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401) {
            // Token expired - try to refresh
            final refreshToken = await _secureStorage.read(
              key: StorageKeys.refreshToken,
            );
            if (refreshToken != null) {
              try {
                final response = await _dio.post(
                  baseUrl + ApiEndpoints.refresh,
                  data: {'refresh': refreshToken},
                );

                // Save new tokens
                await _secureStorage.write(
                  key: StorageKeys.accessToken,
                  value: response.data['access'],
                );

                // Retry original request
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${response.data['access']}';
                final retryResponse = await _dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              } catch (e) {
                // Refresh failed - clear tokens
                await _secureStorage.delete(key: StorageKeys.accessToken);
                await _secureStorage.delete(key: StorageKeys.refreshToken);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

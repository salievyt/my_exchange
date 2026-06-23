import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/drf_error_helper.dart';
import '../models/app_version_model.dart';

/// Notification remote data source
abstract class NotificationRemoteDataSource {
  /// Check if a newer app version is available.
  /// Returns [AppVersionModel] if update is available, or null if up-to-date.
  Future<AppVersionModel?> checkAppVersion({
    required String platform,
    required String currentVersion,
    required int buildNumber,
  });
}

/// Notification remote data source implementation
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AppVersionModel?> checkAppVersion({
    required String platform,
    required String currentVersion,
    required int buildNumber,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.notificationsAppVersion,
        data: {
          'platform': platform,
          'current_version': currentVersion,
          'build_number': buildNumber,
        },
      );

      final data = response.data;
      if (data['update_available'] == true) {
        return AppVersionModel.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка проверки обновлений'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

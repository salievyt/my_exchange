import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/api_constants.dart';
import '../../di/service_locator.dart';
import '../../core/network/dio_client.dart';

/// Report type enum
enum ReportType {
  daily('daily', 'Дневной отчёт'),
  monthly('monthly', 'Месячный отчёт'),
  operations('operations', 'Экспорт операций'),
  cash('cash', 'Экспорт кассы');

  final String value;
  final String displayName;

  const ReportType(this.value, this.displayName);
}

/// Report format enum
enum ReportFormat {
  csv('csv', 'CSV'),
  xlsx('xlsx', 'Excel'),
  pdf('pdf', 'PDF');

  final String value;
  final String displayName;

  const ReportFormat(this.value, this.displayName);
}

/// Provider for downloading report files
class ReportsProvider extends ChangeNotifier {
  final DioClient _dioClient;

  ReportsProvider() : _dioClient = sl<DioClient>();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  double _progress = 0.0;
  String? _savedFilePath;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  double get progress => _progress;
  String? get savedFilePath => _savedFilePath;

  /// Download a report file and share/save it
  Future<bool> downloadReport({
    required ReportType type,
    required ReportFormat format,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    _progress = 0.0;
    _savedFilePath = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'format': format.value,
      };
      final dateStr = DateTime.now().toIso8601String().split('T')[0];
      String endpoint;

      switch (type) {
        case ReportType.daily:
        case ReportType.monthly:
          endpoint = ApiEndpoints.reportsExport;
          queryParams.addAll({
            'type': 'report',
            'date': dateStr,
          });
          break;
        case ReportType.operations:
          endpoint = ApiEndpoints.reportsExport;
          queryParams.addAll({
            'type': 'operations',
            'date_from': dateStr,
          });
          break;
        case ReportType.cash:
          endpoint = ApiEndpoints.reportsExport;
          queryParams.addAll({
            'type': 'cash',
            'date_from': dateStr,
          });
          break;
      }

      final filename = 'my_exchange_${type.value}_$dateStr.${format.value}';

      // Save to app documents directory (persistent storage)
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';

      // Remove old file if exists
      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // Download the file
      await _dioClient.dio.download(
        endpoint,
        filePath,
        queryParameters: queryParams,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            notifyListeners();
          }
        },
      );

      // Verify file exists and has content
      final file = File(filePath);
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Файл не был загружен');
      }

      _savedFilePath = filePath;

      // Open share sheet so user can save / send / open the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'My Exchange — $filename',
        ),
      );

      _isLoading = false;
      _successMessage = 'reports_saved';
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Ошибка: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    // Check for network errors vs server errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер не отвечает. Проверьте подключение к интернету.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Нет подключения к интернету. Проверьте соединение.';
    }
    return 'Ошибка загрузки отчёта';
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

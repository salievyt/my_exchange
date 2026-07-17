import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/drf_error_helper.dart';
import '../models/operation_model.dart';

/// Operation remote data source
abstract class OperationRemoteDataSource {
  Future<List<OperationModel>> getOperations({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
    String? operationType,
    String? currencyId,
    String? dateFrom,
    String? dateTo,
  });

  Future<OperationModel> getOperationById(String id);

  Future<OperationModel> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    required double totalAmount,
    String? clientName,
    String? clientCompany,
    String? comment,
  });

  Future<OperationModel> updateOperation({
    required String id,
    required double amount,
    required double rate,
    String? comment,
    String? clientName,
    String? clientCompany,
  });

  Future<void> deleteOperation(String id);

  Future<OperationModel> cancelOperation({
    required String id,
    double? cancelAmount,
  });

  Future<List<Map<String, dynamic>>> getOperationHistory(String id);

  Future<Map<String, dynamic>> getTodayStats();
}

/// Operation remote data source implementation
class OperationRemoteDataSourceImpl implements OperationRemoteDataSource {
  final DioClient dioClient;

  OperationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<OperationModel>> getOperations({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
    String? operationType,
    String? currencyId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (operationType != null) {
        queryParams['operation_type'] = operationType;
      }
      if (currencyId != null) queryParams['currency'] = currencyId;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await dioClient.dio.get(
        ApiEndpoints.operations,
        queryParameters: queryParams,
      );

      final results =
          response.data['results'] as List? ?? response.data as List;
      return results.map((json) => OperationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения операций'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OperationModel> getOperationById(String id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.operations}$id/',
      );
      return OperationModel.fromJson(response.data);
    } on DioException {
      throw NotFoundException(message: 'Операция не найдена');
    }
  }

  @override
  Future<OperationModel> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
    required double totalAmount,
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    final data = <String, dynamic>{
      'operation_type': operationType,
      'currency': currencyId,
      'rate': rate.toString(),
      'amount': amount.toString(),
      'total_amount': totalAmount.toString(),
    };
    if (clientName != null) data['client_name'] = clientName;
    if (clientCompany != null) data['client_company'] = clientCompany;
    if (comment != null) data['comment'] = comment;

    debugPrint('[API] createOperation -> POST ${ApiEndpoints.operations}');
    debugPrint('[API] Request data: $data');

    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.operations,
        data: data,
      );
      debugPrint('[API] createOperation success (${response.statusCode}): ${response.data}');
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[API] createOperation ERROR (${e.response?.statusCode}):');
      debugPrint('[API]   Request URL: ${e.requestOptions.uri}');
      debugPrint('[API]   Request data: ${e.requestOptions.data}');
      debugPrint('[API]   Response body: ${e.response?.data}');
      debugPrint('[API]   Headers: ${e.response?.headers}');
      debugPrint('[API]   Error: ${e.message}');
      debugPrint('[API]   StackTrace: ${e.stackTrace}');
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка создания операции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OperationModel> updateOperation({
    required String id,
    required double amount,
    required double rate,
    String? comment,
    String? clientName,
    String? clientCompany,
  }) async {
    final data = <String, dynamic>{
      'amount': amount.toString(),
      'rate': rate.toString(),
    };
    if (comment != null) data['comment'] = comment;
    if (clientName != null) data['client_name'] = clientName;
    if (clientCompany != null) data['client_company'] = clientCompany;

    debugPrint('[API] updateOperation($id) -> PATCH ${ApiEndpoints.operations}$id/');
    debugPrint('[API] Request data: $data');

    try {
      final response = await dioClient.dio.patch(
        '${ApiEndpoints.operations}$id/',
        data: data,
      );
      debugPrint('[API] updateOperation success (${response.statusCode}): ${response.data}');
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[API] updateOperation ERROR (${e.response?.statusCode}):');
      debugPrint('[API]   Request URL: ${e.requestOptions.uri}');
      debugPrint('[API]   Request data: ${e.requestOptions.data}');
      debugPrint('[API]   Response body: ${e.response?.data}');
      debugPrint('[API]   Headers: ${e.response?.headers}');
      debugPrint('[API]   Error: ${e.message}');
      debugPrint('[API]   StackTrace: ${e.stackTrace}');
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка обновления операции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteOperation(String id) async {
    debugPrint('[API] deleteOperation($id) -> DELETE ${ApiEndpoints.operations}$id/');
    try {
      await dioClient.dio.delete('${ApiEndpoints.operations}$id/');
      debugPrint('[API] deleteOperation success');
    } on DioException catch (e) {
      debugPrint('[API] deleteOperation ERROR: ${e.message}');
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка удаления операции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OperationModel> cancelOperation({
    required String id,
    double? cancelAmount,
  }) async {
    final data = <String, dynamic>{};
    if (cancelAmount != null) data['cancel_amount'] = cancelAmount.toString();

    debugPrint('[API] cancelOperation($id) -> POST ${ApiEndpoints.operationCancel}$id/cancel/');
    debugPrint('[API] Request data: $data');

    try {
      final response = await dioClient.dio.post(
        '${ApiEndpoints.operationCancel}$id/cancel/',
        data: data,
      );
      debugPrint('[API] cancelOperation success (${response.statusCode}): ${response.data}');
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('[API] cancelOperation ERROR (${e.response?.statusCode}):');
      debugPrint('[API]   Request URL: ${e.requestOptions.uri}');
      debugPrint('[API]   Response body: ${e.response?.data}');
      debugPrint('[API]   Error: ${e.message}');
      debugPrint('[API]   StackTrace: ${e.stackTrace}');
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка отмены операции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOperationHistory(String id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.operationHistory}$id/history/',
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения истории операции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getTodayStats() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.todayStats);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения статистики за сегодня'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/operation_model.dart';

/// Operation remote data source
abstract class OperationRemoteDataSource {
  Future<List<OperationModel>> getOperations({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
    String? operationType,
    String? dateFrom,
    String? dateTo,
  });

  Future<OperationModel> getOperationById(String id);

  Future<OperationModel> createOperation({
    required String operationType,
    required int currencyId,
    required double rate,
    required double amount,
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
        message: 'Ошибка получения операций',
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
    String? clientName,
    String? clientCompany,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{
        'operation_type': operationType,
        'currency': currencyId,
        'rate': rate.toString(),
        'amount': amount.toString(),
      };
      if (clientName != null) {
        data['client_name'] = clientName;
      }
      if (clientCompany != null) {
        data['client_company'] = clientCompany;
      }
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.operations,
        data: data,
      );
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data['detail']?.toString() ??
            'Ошибка создания операции',
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
    try {
      final data = <String, dynamic>{
        'amount': amount.toString(),
        'rate': rate.toString(),
      };
      if (comment != null) {
        data['comment'] = comment;
      }
      if (clientName != null) {
        data['client_name'] = clientName;
      }
      if (clientCompany != null) {
        data['client_company'] = clientCompany;
      }

      final response = await dioClient.dio.patch(
        '${ApiEndpoints.operations}$id/',
        data: data,
      );
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Ошибка обновления операции',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteOperation(String id) async {
    try {
      await dioClient.dio.delete('${ApiEndpoints.operations}$id/');
    } on DioException catch (e) {
      throw ServerException(
        message: 'Ошибка удаления операции',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<OperationModel> cancelOperation({
    required String id,
    double? cancelAmount,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (cancelAmount != null) {
        data['cancel_amount'] = cancelAmount.toString();
      }
      final response = await dioClient.dio.post(
        '${ApiEndpoints.operationCancel}$id/cancel/',
        data: data,
      );
      return OperationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Ошибка отмены операции',
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
        message: 'Ошибка получения истории операции',
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
        message: 'Ошибка получения статистики за сегодня',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/drf_error_helper.dart';
import '../models/cash_balance_model.dart';
import '../models/cash_register_model.dart';
import '../models/cash_transaction_model.dart';

/// Cash remote data source
abstract class CashRemoteDataSource {
  
  Future<List<CashBalanceModel>> getBalances({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<CashBalanceModel> getBalanceById(int id);

  Future<Map<String, dynamic>> getBalanceSummary();

  Future<List<CashBalanceModel>> getLowBalances();

  
  Future<List<CashRegisterModel>> getRegisters({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<CashRegisterModel> getRegisterById(int id);

  Future<CashRegisterModel> getCurrentRegister();

  Future<CashRegisterModel> openRegister({
    required Map<String, double> openingBalance,
    String? comment,
  });

  Future<CashRegisterModel> closeRegister({
    required int id,
    required Map<String, double> closingBalance,
    String? comment,
  });

  Future<CashRegisterModel> updateRegister({
    required int id,
    String? comment,
  });

  
  Future<List<CashTransactionModel>> getTransactions({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<CashTransactionModel> createTransaction({
    required String transactionType,
    required int currencyId,
    required double amount,
    String? comment,
  });

  Future<CashTransactionModel> getTransactionById(int id);

  Future<void> deleteTransaction(int id);
}

/// Cash remote data source implementation
class CashRemoteDataSourceImpl implements CashRemoteDataSource {
  final DioClient dioClient;

  CashRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CashBalanceModel>> getBalances({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await dioClient.dio.get(
        ApiEndpoints.cashBalances,
        queryParameters: queryParams,
      );

      final results =
          response.data['results'] as List? ?? response.data as List;
      return results.map((json) => CashBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения остатков'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashBalanceModel> getBalanceById(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.cashBalances}$id/',
      );
      return CashBalanceModel.fromJson(response.data);
    } on DioException {
      throw NotFoundException(message: 'Остаток не найден');
    }
  }

  @override
  Future<Map<String, dynamic>> getBalanceSummary() async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.cashBalancesSummary,
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения сводки по остаткам'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CashBalanceModel>> getLowBalances() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.cashBalancesLow);
      final results =
          response.data['results'] as List? ?? response.data as List;
      return results.map((json) => CashBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения низких остатков'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CashRegisterModel>> getRegisters({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await dioClient.dio.get(
        ApiEndpoints.cashRegisters,
        queryParameters: queryParams,
      );

      final results =
          response.data['results'] as List? ?? response.data as List;
      return results.map((json) => CashRegisterModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения кассовых смен'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashRegisterModel> getRegisterById(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.cashRegisters}$id/',
      );
      return CashRegisterModel.fromJson(response.data);
    } on DioException {
      throw NotFoundException(message: 'Кассовая смена не найдена');
    }
  }

  @override
  Future<CashRegisterModel> getCurrentRegister() async {
    try {
      final response = await dioClient.dio.get(
        ApiEndpoints.cashRegistersCurrent,
      );
      return CashRegisterModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException(message: 'Активная смена не найдена');
      }
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения текущей смены'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashRegisterModel> openRegister({
    required Map<String, double> openingBalance,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{'opening_balance': openingBalance};
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.cashRegistersOpen,
        data: data,
      );
      return CashRegisterModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка открытия смены'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashRegisterModel> closeRegister({
    required int id,
    required Map<String, double> closingBalance,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{'closing_balance': closingBalance};
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await dioClient.dio.post(
        '${ApiEndpoints.cashRegistersClose}$id/close/',
        data: data,
      );
      return CashRegisterModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка закрытия смены'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashRegisterModel> updateRegister({
    required int id,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await dioClient.dio.patch(
        '${ApiEndpoints.cashRegisters}$id/',
        data: data,
      );
      return CashRegisterModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка обновления смены'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<CashTransactionModel>> getTransactions({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (search != null) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await dioClient.dio.get(
        ApiEndpoints.cashTransactions,
        queryParameters: queryParams,
      );

      final results =
          response.data['results'] as List? ?? response.data as List;
      return results
          .map((json) => CashTransactionModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения транзакций'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashTransactionModel> createTransaction({
    required String transactionType,
    required int currencyId,
    required double amount,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{
        'transaction_type': transactionType,
        'currency': currencyId,
        'amount': amount.toString(),
      };
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await dioClient.dio.post(
        ApiEndpoints.cashTransactions,
        data: data,
      );
      return CashTransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка создания транзакции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CashTransactionModel> getTransactionById(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.cashTransactions}$id/',
      );
      return CashTransactionModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw NotFoundException(message: 'Транзакция не найдена');
      }
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения транзакции'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteTransaction(int id) async {
    try {
      await dioClient.dio.delete('${ApiEndpoints.cashTransactions}$id/');
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка удаления транзакции'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

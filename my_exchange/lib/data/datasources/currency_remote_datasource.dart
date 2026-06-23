import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/drf_error_helper.dart';
import '../models/currency_model.dart';

/// Currency remote data source
abstract class CurrencyRemoteDataSource {
  Future<List<CurrencyModel>> getCurrencies({
    int? page,
    int? pageSize,
    String? search,
    String? ordering,
  });

  Future<List<CurrencyModel>> getActiveCurrencies();

  Future<CurrencyModel> getCurrencyById(int id);

  Future<CurrencyModel> createCurrency({
    required String code,
    required String name,
    String? symbol,
    required double? buyRate,
    required double? sellRate,
    required bool isActive,
  });

  Future<CurrencyModel> updateCurrency({
    required int id,
    String? code,
    String? name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool? isActive,
  });

  Future<void> deleteCurrency(int id);

  Future<List<Map<String, dynamic>>> getCurrencyHistory(int id);
}

/// Currency remote data source implementation
class CurrencyRemoteDataSourceImpl implements CurrencyRemoteDataSource {
  final DioClient dioClient;

  CurrencyRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CurrencyModel>> getCurrencies({
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
        ApiEndpoints.currencies,
        queryParameters: queryParams,
      );

      final data = response.data;
      final List<dynamic> results;
      if (data is List) {
        results = data;
      } else {
        results = (data['results'] as List?) ?? data as List;
      }
      return results.map((json) => CurrencyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения валют'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(
        message: 'Ошибка обработки данных валют: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<CurrencyModel>> getActiveCurrencies() async {
    try {
      final response = await dioClient.dio.get(ApiEndpoints.currenciesActive);
      
      final data = response.data;
      final List<dynamic> results;
      if (data is List) {
        results = data;
      } else {
        results = (data['results'] as List?) ?? data as List;
      }
      return results.map((json) => CurrencyModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения активных валют'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(
        message: 'Ошибка обработки данных валют: ${e.toString()}',
      );
    }
  }

  @override
  Future<CurrencyModel> getCurrencyById(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.currencies}$id/',
      );
      return CurrencyModel.fromJson(response.data);
    } on DioException {
      throw NotFoundException(message: 'Валюта не найдена');
    }
  }

  @override
  Future<CurrencyModel> createCurrency({
    required String code,
    required String name,
    String? symbol,
    required double? buyRate,
    required double? sellRate,
    required bool isActive,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiEndpoints.currencies,
        data: {
          'code': code,
          'name': name,
          if (symbol != null) 'symbol': symbol,
          if (buyRate != null) 'buy_rate': buyRate,
          if (sellRate != null) 'sell_rate': sellRate,
          'is_active': isActive,
        },
      );
      return CurrencyModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка создания валюты'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<CurrencyModel> updateCurrency({
    required int id,
    String? code,
    String? name,
    String? symbol,
    double? buyRate,
    double? sellRate,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (code != null) data['code'] = code;
      if (name != null) data['name'] = name;
      if (symbol != null) data['symbol'] = symbol;
      if (buyRate != null) data['buy_rate'] = buyRate;
      if (sellRate != null) data['sell_rate'] = sellRate;
      if (isActive != null) data['is_active'] = isActive;

      final response = await dioClient.dio.patch(
        '${ApiEndpoints.currencies}$id/',
        data: data,
      );
      return CurrencyModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка обновления валюты'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteCurrency(int id) async {
    try {
      await dioClient.dio.delete('${ApiEndpoints.currencies}$id/');
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка удаления валюты'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCurrencyHistory(int id) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiEndpoints.currencyHistory}$id/history/',
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw ServerException(
        message: extractDrfErrorMessage(e, 'Ошибка получения истории курса'),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

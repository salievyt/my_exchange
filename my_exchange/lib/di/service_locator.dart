import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/cash_remote_datasource.dart';
import '../../data/datasources/currency_remote_datasource.dart';
import '../../data/datasources/operation_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/cash_repository_impl.dart';
import '../../data/repositories/currency_repository_impl.dart';
import '../../data/repositories/operation_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/cash_repository.dart';
import '../../domain/repositories/currency_repository.dart';
import '../../domain/repositories/operation_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/operation_usecases.dart';
import '../../core/network/dio_client.dart' as core;

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(
        milliseconds: AppConstants.connectionTimeout,
      ),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  sl.registerLazySingleton<Dio>(() => dio);

  // Network
  sl.registerLazySingleton<DioClient>(
    () => DioClient(sl<Dio>(), sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<core.NetworkInfo>(() => core.NetworkInfoImpl());

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      dioClient: sl<DioClient>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<CurrencyRemoteDataSource>(
    () => CurrencyRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<OperationRemoteDataSource>(
    () => OperationRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<CashRemoteDataSource>(
    () => CashRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      networkInfo: sl<core.NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton<CurrencyRepository>(
    () => CurrencyRepositoryImpl(
      remoteDataSource: sl<CurrencyRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<OperationRepository>(
    () => OperationRepositoryImpl(
      remoteDataSource: sl<OperationRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<CashRepository>(
    () => CashRepositoryImpl(remoteDataSource: sl<CashRemoteDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckAuthUseCase(sl<AuthRepository>()));

  sl.registerLazySingleton(
    () => GetOperationsUseCase(sl<OperationRepository>()),
  );
  sl.registerLazySingleton(
    () => CreateOperationUseCase(sl<OperationRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTodayStatsUseCase(sl<OperationRepository>()),
  );
}

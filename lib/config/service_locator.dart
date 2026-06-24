import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:maucoffee/config/user_preference.dart';
import 'package:maucoffee/data/api/api_service.dart';
import 'package:maucoffee/home/cubit/employee_cubit.dart';
import 'package:maucoffee/repository/category_repository.dart';
import 'package:maucoffee/repository/employee_repository.dart';
import 'package:maucoffee/repository/expense_repository.dart';
import 'package:maucoffee/repository/order_repository.dart';
import 'package:maucoffee/repository/product_repository.dart';
import 'package:maucoffee/repository/absensi_repository.dart';
import 'package:maucoffee/services/offline_storage_service.dart';
import 'package:maucoffee/features/cubit/absensi_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant.dart';
import 'env/env.dart';

/// Global [GetIt.instance].
final GetIt serviceLocator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<UserPreference>(UserPreference(prefs));

  serviceLocator.registerFactory<Dio>(() {
    final dio = Dio();
    kDebugMode ? dio.interceptors.add(AwesomeDioInterceptor()) : null;
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: timeOutDuration),
      receiveTimeout: const Duration(seconds: timeOutDuration),
      persistentConnection: false,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "x-api-key": Env.apiKey,
        'Authorization':
            'Bearer ${serviceLocator.get<UserPreference>().getToken()}',
      },
    );

    return dio;
  });

  serviceLocator.registerFactory<ApiService>(
    () => ApiService(serviceLocator.get<Dio>(), baseUrl: baseApi),
  );

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  serviceLocator.registerSingleton<PackageInfo>(packageInfo);

  // Daftarkan semua Repository ke Service Locator sebagai Factory
  serviceLocator.registerFactory<CategoryRepository>(
    () => CategoryRepository(),
  );
  serviceLocator.registerFactory<ProductRepository>(
    () => ProductRepository(),
  );
  serviceLocator.registerFactory<EmployeeRepository>(
    () => EmployeeRepository(),
  );
  serviceLocator.registerFactory<ExpenseRepository>(
    () => ExpenseRepository(),
  );
  serviceLocator.registerFactory<OrderRepository>(
    () => OrderRepository(),
  );
  serviceLocator.registerFactory<AbsensiRepository>(
    () => AbsensiRepository(),
  );
  serviceLocator.registerFactory<OfflineStorageService>(
    () => OfflineStorageService(),
  );
  serviceLocator.registerFactory<AbsensiCubit>(
    () => AbsensiCubit(serviceLocator<AbsensiRepository>()),
  );
  serviceLocator.registerFactory<EmployeeCubit>(
    () => EmployeeCubit(serviceLocator<EmployeeRepository>()),
  );
}

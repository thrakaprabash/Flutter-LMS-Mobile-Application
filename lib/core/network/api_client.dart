import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient(TokenStorage storage, {Dio? client, Dio? refreshClient})
    : dio = client ?? Dio(options()) {
    dio.interceptors.add(
      AuthInterceptor(dio, refreshClient ?? Dio(options()), storage),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          handler.next(error.copyWith(error: ApiException.fromDio(error)));
        },
      ),
    );
  }
  final Dio dio;
  static BaseOptions options() => BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  );
}

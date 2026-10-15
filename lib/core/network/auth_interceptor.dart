import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.dio, this.refreshDio, this.storage);
  final Dio dio;
  final Dio refreshDio;
  final TokenStorage storage;
  Future<String?>? _refreshing;
  bool _public(RequestOptions request) =>
      request.extra['requiresAuth'] == false ||
      request.path.startsWith('/api/v1/auth/');

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_public(options)) {
        final token = await storage.readAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  Future<String?> _refresh() async {
    try {
      final token = await storage.readRefreshToken();
      if (token == null) {
        await storage.clear();
        return null;
      }
      final response = await refreshDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': token},
      );
      final tokens = response.data['data']['tokens'];
      final access = tokens['accessToken'] as String;
      final refresh = tokens['refreshToken'] as String;
      if (access.isEmpty || refresh.isEmpty) {
        throw const FormatException('Empty tokens');
      }
      await storage.saveSession(
        accessToken: access,
        refreshToken: refresh,
        role: await storage.readRole() ?? '',
      );
      return access;
    } catch (_) {
      await storage.clear();
      return null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final error = err;
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        _public(request) ||
        request.extra['authRetried'] == true) {
      return handler.next(error);
    }
    try {
      final current = await storage.readAccessToken();
      String? token;
      if (current != null &&
          request.headers['Authorization'] != 'Bearer $current') {
        token = current;
      } else {
        final pending = _refreshing ??= _refresh();
        try {
          token = await pending;
        } finally {
          if (identical(_refreshing, pending)) _refreshing = null;
        }
      }
      if (token == null) return handler.next(error);
      request.extra['authRetried'] = true;
      request.headers['Authorization'] = 'Bearer $token';
      if (request.data is FormData) {
        request.data = (request.data as FormData).clone();
      }
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(error);
    }
  }
}

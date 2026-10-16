import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class AccountService {
  AccountService(this.client);
  final ApiClient client;
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    ProgressCallback? progress,
  }) async {
    final response = await client.dio.request<dynamic>(
      path,
      data: data,
      onSendProgress: progress,
      options: Options(method: method, extra: {'requiresAuth': !public}),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> auth(
    String operation,
    Map<String, dynamic> data,
  ) => request('POST', '/api/v1/auth/$operation', data: data, public: true);
  Future<Map<String, dynamic>> fullProfile() async => Map<String, dynamic>.from(
    (await request('GET', '/api/v1/users/me/full-profile'))['data'] as Map,
  );
}

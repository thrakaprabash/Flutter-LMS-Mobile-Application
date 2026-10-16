import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/services/account_service.dart';

class AuthProvider extends ChangeNotifier {
  bool get isDemo => false;
  AuthProvider(this.service, this.storage);
  final AccountService service;
  final TokenStorage storage;
  Map<String, dynamic>? user;
  Map<String, dynamic>? profile;
  bool restoring = false;
  String? restoreError;
  String? get role => user?['role'] as String?;
  String get route => switch (role) {
    'STUDENT' => '/student',
    'INSTRUCTOR' => '/instructor',
    'ADMIN' => '/admin',
    _ => '/',
  };
  bool get authenticated => user != null;
  static String message(Object error) => error is DioException
      ? ApiException.fromDio(error).message
      : error is ApiException
      ? error.message
      : 'Unable to complete this request. Please try again.';

  Future<void> accept(Map<String, dynamic> response) async {
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final account = Map<String, dynamic>.from(data['user'] as Map);
    if (!['STUDENT', 'INSTRUCTOR', 'ADMIN'].contains(account['role'])) {
      throw const ApiException(message: 'This account role is not supported.');
    }
    final tokens = data['tokens'] as Map;
    final access = tokens['accessToken'] as String;
    final refresh = tokens['refreshToken'] as String;
    if (access.isEmpty || refresh.isEmpty) {
      throw const ApiException(
        message: 'The server returned an incomplete session.',
      );
    }
    await storage.saveSession(
      accessToken: access,
      refreshToken: refresh,
      role: account['role'] as String,
    );
    user = account;
    profile = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    final data = await service.fullProfile();
    final account = Map<String, dynamic>.from(data['user'] as Map);
    if (!['STUDENT', 'INSTRUCTOR', 'ADMIN'].contains(account['role'])) {
      await invalidate();
      throw const ApiException(message: 'This account role is not supported.');
    }
    user = account;
    final raw =
        data['profile'] ?? data['studentProfile'] ?? data['instructorProfile'];
    profile = raw is Map ? Map<String, dynamic>.from(raw) : null;
    notifyListeners();
  }

  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    notifyListeners();
    try {
      if (await storage.readRefreshToken() != null) await loadProfile();
    } catch (error) {
      if (error is DioException &&
          [401, 403].contains(error.response?.statusCode)) {
        await invalidate();
      } else {
        restoreError = message(error);
      }
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> invalidate() async {
    user = null;
    profile = null;
    notifyListeners();
    await storage.clear();
  }

  Future<void> logout({bool all = false}) async {
    await service.request(
      'POST',
      '/api/v1/auth/${all ? 'logout-all' : 'logout'}',
    );
    await invalidate();
  }
}

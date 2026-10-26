import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

import 'core_api_test.dart' show FakeAdapter, body;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage storage;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const TokenStorage(FlutterSecureStorage());
  });
  Map<String, dynamic> session(String role) => {
    'data': {
      'user': {'role': role},
      'tokens': {'accessToken': 'access', 'refreshToken': 'refresh'},
    },
  };
  for (final role in ['STUDENT', 'INSTRUCTOR', 'ADMIN']) {
    test('$role stores secure tokens and routes by backend role', () async {
      final auth = AuthProvider(AccountService(ApiClient(storage)), storage);
      await auth.accept(session(role));
      expect(auth.route, '/${role.toLowerCase()}');
      expect(await storage.readRole(), role);
      expect(await storage.readRefreshToken(), 'refresh');
    });
  }
  test('unsupported role cannot create session', () async {
    final auth = AuthProvider(AccountService(ApiClient(storage)), storage);
    await expectLater(auth.accept(session('OWNER')), throwsException);
    expect(auth.authenticated, isFalse);
    expect(await storage.readAccessToken(), isNull);
  });
  for (final succeeds in [true, false]) {
    test(
      'account deactivation clears session only on success=$succeeds',
      () async {
        final dio = Dio(ApiClient.options())
          ..httpClientAdapter = FakeAdapter((request) {
            expect(request.method, 'PATCH');
            expect(request.path, '/api/v1/users/me/deactivate');
            expect(request.headers['Authorization'], 'Bearer access');
            expect(request.data, isNull);
            return body(succeeds ? 200 : 500, {'message': 'Result'});
          });
        final auth = AuthProvider(
          AccountService(ApiClient(storage, client: dio)),
          storage,
        );
        await auth.accept(session('STUDENT'));
        auth.profile = {'educationLevel': 'Undergraduate'};
        if (succeeds) {
          await auth.deactivateAccount();
          expect(auth.profile, isNull);
          expect(await storage.readAccessToken(), isNull);
          expect(await storage.readRefreshToken(), isNull);
          expect(await storage.readRole(), isNull);
        } else {
          await expectLater(auth.deactivateAccount(), throwsException);
          expect(auth.profile, isNotNull);
          expect(await storage.readRefreshToken(), 'refresh');
        }
        expect(auth.authenticated, !succeeds);
      },
    );
  }
  test(
    'admin cannot deactivate account or send a deactivation request',
    () async {
      final dio = Dio(ApiClient.options())
        ..httpClientAdapter = FakeAdapter((request) {
          fail('Admin deactivation must not reach the backend.');
        });
      final auth = AuthProvider(
        AccountService(ApiClient(storage, client: dio)),
        storage,
      );
      await auth.accept(session('ADMIN'));
      expect(auth.canDeactivateAccount, isFalse);
      await expectLater(auth.deactivateAccount(), throwsException);
      expect(auth.authenticated, isTrue);
      expect(await storage.readRefreshToken(), 'refresh');
    },
  );
  test('restore gets current backend role and profile', () async {
    await storage.saveSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'STUDENT',
    );
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((request) {
        expect(request.path, '/api/v1/users/me/full-profile');
        expect(request.headers['Authorization'], 'Bearer access');
        return body(200, {
          'data': {
            'user': {'role': 'INSTRUCTOR'},
            'profile': {'headline': 'Teacher'},
          },
        });
      });
    final auth = AuthProvider(
      AccountService(ApiClient(storage, client: dio)),
      storage,
    );
    await auth.restore();
    expect(auth.route, '/instructor');
    expect(auth.profile?['headline'], 'Teacher');
  });
  test('offline restore preserves tokens for retry', () async {
    await storage.saveSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'STUDENT',
    );
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter(
        (request) => throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        ),
      );
    final auth = AuthProvider(
      AccountService(ApiClient(storage, client: dio)),
      storage,
    );
    await auth.restore();
    expect(auth.restoreError, contains('Cannot connect'));
    expect(await storage.readRefreshToken(), 'refresh');
  });
  for (final all in [false, true]) {
    test('logout all=$all sends bearer then clears local session', () async {
      final dio = Dio(ApiClient.options())
        ..httpClientAdapter = FakeAdapter((request) {
          expect(request.path, '/api/v1/auth/${all ? 'logout-all' : 'logout'}');
          expect(request.headers['Authorization'], 'Bearer access');
          expect(request.data, isNull);
          return body(200, {'message': 'Logged out'});
        });
      final auth = AuthProvider(
        AccountService(ApiClient(storage, client: dio)),
        storage,
      );
      await auth.accept(session('STUDENT'));
      await auth.logout(all: all);
      expect(auth.authenticated, isFalse);
      expect(await storage.readAccessToken(), isNull);
    });
  }
  test('refresh failure notifies navigation', () async {
    await storage.saveSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: 'STUDENT',
    );
    var expired = 0;
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) => body(401, {}));
    final refresh = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) => body(401, {}));
    final client = ApiClient(
      storage,
      client: dio,
      refreshClient: refresh,
      onSessionExpired: () => expired++,
    );
    await expectLater(
      client.dio.get<dynamic>('/api/v1/users/me'),
      throwsA(isA<DioException>()),
    );
    expect(expired, 1);
  });
}

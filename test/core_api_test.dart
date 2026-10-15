import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/core/network/api_response.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, dynamic data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TokenStorage storage;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const TokenStorage(FlutterSecureStorage());
    await storage.saveSession(
      accessToken: 'old',
      refreshToken: 'refresh',
      role: 'STUDENT',
    );
  });
  test(
    '401 refresh rotates both tokens and retries with the new bearer',
    () async {
      var calls = 0;
      final dio = Dio(ApiClient.options())
        ..httpClientAdapter = FakeAdapter((request) {
          calls++;
          expect(
            request.headers['Authorization'],
            calls == 1 ? 'Bearer old' : 'Bearer new',
          );
          return body(calls == 1 ? 401 : 200, {'data': {}});
        });
      final refresh = Dio(ApiClient.options())
        ..httpClientAdapter = FakeAdapter((request) {
          expect(request.path, '/api/v1/auth/refresh-token');
          expect(request.data, {'refreshToken': 'refresh'});
          return body(200, {
            'data': {
              'tokens': {'accessToken': 'new', 'refreshToken': 'rotated'},
            },
          });
        });
      await ApiClient(
        storage,
        client: dio,
        refreshClient: refresh,
      ).dio.get<dynamic>('/api/v1/users/me');
      expect(calls, 2);
      expect(await storage.readRefreshToken(), 'rotated');
      expect(await storage.readRole(), 'STUDENT');
    },
  );
  test('failed refresh clears session without a retry loop', () async {
    var refreshCalls = 0;
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter(
        (_) => body(401, {'message': 'Expired'}),
      );
    final refresh = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) {
        refreshCalls++;
        return body(401, {});
      });
    await expectLater(
      ApiClient(
        storage,
        client: dio,
        refreshClient: refresh,
      ).dio.get<dynamic>('/api/v1/users/me'),
      throwsA(isA<DioException>()),
    );
    expect(refreshCalls, 1);
    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });
  test('login failure never refreshes', () async {
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((request) {
        expect(request.headers.containsKey('Authorization'), false);
        return body(401, {'message': 'Invalid credentials'});
      });
    final refresh = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter(
        (_) => throw StateError('Must not refresh'),
      );
    await expectLater(
      ApiClient(
        storage,
        client: dio,
        refreshClient: refresh,
      ).dio.post<dynamic>('/api/v1/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.readAccessToken(), 'old');
  });
  test('concurrent expired requests share one refresh', () async {
    var refreshCalls = 0;
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter(
        (request) => body(
          request.headers['Authorization'] == 'Bearer new' ? 200 : 401,
          {'data': {}},
        ),
      );
    final refresh = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) {
        refreshCalls++;
        return body(200, {
          'data': {
            'tokens': {'accessToken': 'new', 'refreshToken': 'rotated'},
          },
        });
      });
    final client = ApiClient(storage, client: dio, refreshClient: refresh);
    await Future.wait(
      List.generate(4, (_) => client.dio.get<dynamic>('/api/v1/users/me')),
    );
    expect(refreshCalls, 1);
  });

  test('a retried 401 stops after one refresh', () async {
    var calls = 0;
    var refreshCalls = 0;
    final dio = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) {
        calls++;
        return body(401, {});
      });
    final refresh = Dio(ApiClient.options())
      ..httpClientAdapter = FakeAdapter((_) {
        refreshCalls++;
        return body(200, {
          'data': {
            'tokens': {'accessToken': 'new', 'refreshToken': 'rotated'},
          },
        });
      });
    await expectLater(
      ApiClient(
        storage,
        client: dio,
        refreshClient: refresh,
      ).dio.get<dynamic>('/api/v1/users/me'),
      throwsA(isA<DioException>()),
    );
    expect(calls, 2);
    expect(refreshCalls, 1);
  });

  test('response mapping preserves pagination and readable failures', () {
    final result = ApiResponse.fromJson({
      'data': [1],
      'pagination': {'page': 2},
    }, (data) => data as List);
    expect(result.pagination?['page'], 2);
    expect(
      () => ApiResponse.fromJson({
        'success': false,
        'message': 'Invalid email',
      }, (data) => data),
      throwsA(isA<ApiException>()),
    );
    expect(
      ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      ).message,
      contains('timed out'),
    );
  });
}

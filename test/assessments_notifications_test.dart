import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/student/services/student_activity_service.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';

import 'core_api_test.dart' show FakeAdapter, body;

class CaptureAccount extends AccountService {
  CaptureAccount(super.client);
  final forms = <FormData>[];
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    ProgressCallback? progress,
  }) async {
    expect(method, 'POST');
    expect(path, '/api/v1/assignments/returned-id/submissions');
    forms.add(data! as FormData);
    return {
      'data': {'status': 'SUBMITTED'},
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'all three assignment payloads are multipart and empty input is rejected',
    () async {
      final account = CaptureAccount(ApiClient(storage));
      final s = StudentActivityService(account);
      await s.submitAssignment('returned-id', text: ' answer ');
      await s.submitAssignment(
        'returned-id',
        text: '',
        file: MultipartFile.fromBytes([1, 2], filename: 'work.pdf'),
      );
      await s.submitAssignment(
        'returned-id',
        text: 'answer',
        file: MultipartFile.fromBytes([3], filename: 'work.pdf'),
      );
      expect(account.forms[0].fields.single.value, 'answer');
      expect(account.forms[0].files, isEmpty);
      expect(account.forms[1].fields, isEmpty);
      expect(account.forms[1].files.single.key, 'file');
      expect(account.forms[2].fields.single.key, 'textAnswer');
      expect(account.forms[2].files.single.value.filename, 'work.pdf');
      expect(
        () => s.submitAssignment('returned-id', text: ' '),
        throwsArgumentError,
      );
    },
  );
  test(
    'protected requests retain authorization and public reviews omit it',
    () async {
      await storage.saveSession(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        role: 'STUDENT',
      );
      final client = ApiClient(storage);
      final calls = <String>[];
      client.dio.httpClientAdapter = FakeAdapter((r) {
        calls.add('${r.method} ${r.uri.path}');
        expect(
          r.headers['Authorization'],
          r.uri.path.endsWith('/reviews') ? isNull : 'Bearer test-access',
        );
        return body(200, {
          'data': {
            'reviews': [],
            'pagination': {'hasNextPage': true},
            'percentage': 37,
            'passed': false,
          },
        });
      });
      final s = StudentActivityService(AccountService(client));
      expect(
        (await s.list(
          '/api/v1/courses/returned-id/reviews',
          'reviews',
          2,
          public: true,
        )).hasNext,
        isTrue,
      );
      final result = await s.mutate(
        'POST',
        '/api/v1/quiz-attempts/returned-attempt/submit',
        data: {'answers': []},
      );
      expect(result['percentage'], 37);
      expect(result['passed'], false);
      await s.mutate('PATCH', '/api/v1/notifications/me/read-all');
      expect(calls, contains('PATCH /api/v1/notifications/me/read-all'));
    },
  );
}

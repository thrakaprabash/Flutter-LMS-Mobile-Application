import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/student/learning/services/learning_service.dart';
import 'package:flutter_lms/features/student/learning/screens/learning_screens.dart';

import 'core_api_test.dart' show FakeAdapter, body;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('enrollments resolve missing instructor names and preserve progress on detail failure', () async {
    await storage.saveSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      role: 'STUDENT',
    );
    final client = ApiClient(storage);
    final calls = <String>[];
    client.dio.httpClientAdapter = FakeAdapter((request) {
      calls.add(request.uri.path);
      if (request.uri.path == '/api/v1/enrollments/me') {
        return body(200, {
          'data': {
            'enrollments': [
              {
                'id': 'one',
                'courseId': {'id': 'course', 'instructorId': 'teacher'},
                'progressPercentage': 42,
              },
              {
                'id': 'two',
                'courseId': {'id': 'course'},
                'progressPercentage': 10,
              },
              {
                'id': 'three',
                'courseId': {'id': 'unavailable'},
                'progressPercentage': 15,
              },
              {
                'id': 'four',
                'courseId': {
                  'id': 'complete',
                  'instructorId': {'firstName': 'Alex'},
                },
              },
            ],
            'pagination': {'hasNextPage': true},
          },
        });
      }
      if (request.uri.path.endsWith('/unavailable')) {
        return body(404, {'message': 'Unavailable'});
      }
      return body(200, {
        'data': {
          'course': {
            'id': 'course',
            'title': 'Flutter',
            'instructorId': {'firstName': 'Alex', 'lastName': 'Taylor'},
          },
        },
      });
    });
    final result = await LearningService(AccountService(client))
        .enrollments(1, 'ACTIVE');
    expect(
      object(
        object(result.items.first['courseId'])['instructorId'],
      )['firstName'],
      'Alex',
    );
    expect(result.items.first['progressPercentage'], 42);
    expect(result.items[2]['progressPercentage'], 15);
    expect(result.items, hasLength(4));
    expect(result.hasNext, isTrue);
    expect(
      calls.where((path) => path == '/api/v1/courses/course'),
      hasLength(1),
    );
    expect(calls, isNot(contains('/api/v1/courses/complete')));
  });
  test('real transport follows endpoint methods, public access and nested pagination', () async {
    await storage.saveSession(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
      role: 'STUDENT',
    );
    final client = ApiClient(storage);
    final calls = <String>[];
    client.dio.httpClientAdapter = FakeAdapter((r) {
      calls.add('${r.method} ${r.uri.path}');
      if (r.uri.path == '/api/v1/courses') {
        expect(
          r.queryParameters['search'] ?? r.uri.queryParameters['search'],
          'dart & flutter',
        );
        expect(r.headers['Authorization'], isNull);
        return body(200, {
          'data': {
            'courses': [
              {'id': 'returned-course', 'title': 'Test'},
            ],
            'pagination': {'page': 1, 'totalPages': 2, 'hasNextPage': true},
          },
        });
      }
      expect(r.headers['Authorization'], 'Bearer test-access');
      return body(200, {'data': {}});
    });
    final s = LearningService(AccountService(client));
    final page = await s.catalogue(search: 'dart & flutter');
    expect(page.hasNext, isTrue);
    expect(recordId(page.items.single), 'returned-course');
    await s.enroll(recordId(page.items.single));
    await s.start('returned-lesson');
    await s.complete('returned-lesson');
    await s.progress('returned-course');
    expect(
      calls,
      containsAllInOrder([
        'POST /api/v1/courses/returned-course/enroll',
        'PATCH /api/v1/lessons/returned-lesson/start',
        'PATCH /api/v1/lessons/returned-lesson/complete',
        'GET /api/v1/courses/returned-course/progress/me',
      ]),
    );
  });
  test(
    'protected learning preserves forbidden and missing-content errors',
    () async {
      final client = ApiClient(storage);
      client.dio.httpClientAdapter = FakeAdapter(
        (r) => body(r.uri.path.endsWith('/start') ? 403 : 404, {
          'message': r.uri.path.endsWith('/start')
              ? 'Enrollment required.'
              : 'Lesson not found.',
        }),
      );
      final service = LearningService(AccountService(client));
      await expectLater(
        service.start('returned-lesson'),
        throwsA(
          predicate(
            (e) => learningError(e as Object) == 'Enrollment required.',
          ),
        ),
      );
      await expectLater(
        service.lesson('returned-lesson'),
        throwsA(
          predicate((e) => learningError(e as Object) == 'Lesson not found.'),
        ),
      );
    },
  );
}

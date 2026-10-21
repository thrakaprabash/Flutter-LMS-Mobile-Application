import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/demo/demo_screen.dart';
import 'package:flutter_lms/features/demo/demo_learning_service.dart';
import 'package:flutter_lms/features/student/learning/services/learning_service.dart';
import 'package:flutter_lms/features/student/learning/screens/learning_screens.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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
    'demo learning never sends backend requests and resets per session',
    () async {
      final client = ApiClient(storage);
      client.dio.httpClientAdapter = FakeAdapter(
        (_) => throw StateError('Demo reached backend'),
      );
      final s = DemoLearningService(AccountService(client));
      await s.enroll('demo-course');
      await s.complete('demo-TEXT');
      await s.complete('demo-TEXT');
      expect(
        object(
          (await s.progress('demo-course'))['enrollment'],
        )['progressPercentage'],
        closeTo(100 / 3, 0.001),
      );
      expect((await s.enrollments(1, 'ACTIVE')).items, hasLength(1));
      expect(
        (await DemoLearningService(
          AccountService(client),
        ).enrollments(1, 'ACTIVE')).items,
        isEmpty,
      );
    },
  );
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
  testWidgets('student browse fits narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = DemoAuthProvider(
      DemoAccountService(ApiClient(storage), 'STUDENT'),
      storage,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: StudentLearningHome()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Find your next course'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'demo student browses, enrolls, completes a lesson and refreshes progress',
    (tester) async {
      final auth = DemoAuthProvider(
        DemoAccountService(ApiClient(storage), 'STUDENT'),
        storage,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(home: StudentLearningHome()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('View course'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('View course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View course'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enroll now'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Getting started'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Getting started'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore text lessons'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore text lessons'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark complete'));
      await tester.pumpAndSettle();
      expect(find.text('Lesson completed'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('33.3%'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('33.3%'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Getting started'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Completed'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

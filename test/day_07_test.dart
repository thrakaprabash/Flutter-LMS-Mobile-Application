import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/assessments/assignment_screen.dart';
import 'package:flutter_lms/features/assessments/notifications_screen.dart';
import 'package:flutter_lms/features/assessments/quiz_screen.dart';
import 'package:flutter_lms/features/assessments/reviews_screen.dart';
import 'package:flutter_lms/features/assessments/student_activity_service.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/demo/demo_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

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

  DemoAccountService demo() {
    final client = ApiClient(storage);
    client.dio.httpClientAdapter = FakeAdapter(
      (_) => throw StateError('Demo contacted backend'),
    );
    return DemoAccountService(client, 'STUDENT');
  }

  Widget screen(DemoAccountService service, Widget child) =>
      ChangeNotifierProvider<AuthProvider>.value(
        value: DemoAuthProvider(service, storage),
        child: MaterialApp(home: child),
      );

  testWidgets('resubmission displays feedback and saves a corrected answer', (
    tester,
  ) async {
    final service = demo();
    await tester.pumpWidget(
      screen(service, const AssignmentScreen(id: 'demo-assignment')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Add a clear explanation'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Corrected layout explanation',
    );
    await tester.ensureVisible(find.text('Submit correction'));
    await tester.tap(find.text('Submit correction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(
      service.activity.submissions['demo-assignment']?['status'],
      'SUBMITTED',
    );
    expect(find.text('Assignment submitted.'), findsOneWidget);
  });
  testWidgets('graded submission disables every edit action', (tester) async {
    await tester.pumpWidget(
      screen(demo(), const AssignmentScreen(id: 'demo-graded')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Submit assignment'),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Marks: 85'), findsOneWidget);
  });
  testWidgets('quiz starts, selects an option and displays returned result', (
    tester,
  ) async {
    await tester.pumpWidget(screen(demo(), const QuizScreen(id: 'demo-quiz')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Column'));
    await tester.ensureVisible(find.text('Submit quiz'));
    await tester.tap(find.text('Submit quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Percentage: 100%'), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
  });
  testWidgets('notifications refresh count after read, read all and deletion', (
    tester,
  ) async {
    final service = demo();
    await tester.pumpWidget(screen(service, const NotificationsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('2 unread'), findsOneWidget);
    await tester.tap(find.text('Welcome to your learning space'));
    await tester.pumpAndSettle();
    expect(find.text('1 unread'), findsOneWidget);
    await tester.tap(find.text('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('0 unread'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete notification').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(service.activity.notifications, hasLength(1));
  });
  testWidgets('review creation becomes editing without creating a duplicate', (
    tester,
  ) async {
    final service = demo();
    await tester.pumpWidget(
      screen(
        service,
        const ReviewsScreen(courseId: 'demo-course', eligible: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Helpful course');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();
    expect(find.text('Edit your review'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated review');
    await tester.tap(find.text('Update review'));
    await tester.pumpAndSettle();
    expect(service.activity.reviews, hasLength(1));
    expect(service.activity.reviews.single['comment'], 'Updated review');
  });
}

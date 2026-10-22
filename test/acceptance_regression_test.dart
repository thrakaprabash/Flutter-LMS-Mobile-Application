import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_lms/core/network/api_exception.dart';
import 'package:flutter_lms/features/student/assignments/screens/assignment_screen.dart';
import 'package:flutter_lms/features/student/notifications/screens/notifications_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

import 'admin_management_test.dart' as fixtures;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lms/core/theme/app_theme.dart';
import 'package:flutter_lms/core/widgets/app_state_view.dart';
import 'package:flutter_lms/features/auth/widgets/auth_layout.dart';
import 'package:flutter_lms/shared/widgets/confirmation_dialog.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(800, 1024),
  ]) {
    testWidgets(
      'account form remains scrollable at $size with large text and keyboard',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                viewInsets: const EdgeInsets.only(bottom: 150),
              ),
              child: child!,
            ),
            home: AuthLayout(
              title: 'Welcome back',
              subtitle: 'Sign in to continue your learning.',
              child: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Email address'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Password'),
                  ),
                  AuthSubmitButton(
                    label: 'Sign in',
                    busy: false,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Sign in').hitTestable(), findsOneWidget);
      },
    );
  }
  testWidgets(
    'long destructive confirmation scrolls and defaults to cancellation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await confirmActivity(
                    context,
                    'Archive this course?',
                    List.filled(
                      30,
                      'Existing learners may lose access to this content.',
                    ).join(' '),
                  );
                },
                child: const Text('Archive'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, false);
    },
  );
  testWidgets(
    'error state exposes a working retry on a small landscape screen',
    (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppStateView(
              status: UiStatus.error,
              title: 'Unable to load courses',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: () => retries++,
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in ['GRADED', 'RESUBMISSION_REQUIRED']) {
    testWidgets('$status assignment uses backend status to control editing', (
      tester,
    ) async {
      final account = fixtures.AdminAccount();
      account.respond = (method, path, data) async => {
        'data': path.endsWith('/submission/me')
            ? {
                'submission': {
                  'status': status,
                  'textAnswer': 'Previous answer',
                  'feedback': 'Review the final section.',
                },
              }
            : {
                'assignment': {
                  '_id': 'returned-assignment',
                  'title': 'Practice',
                  'maxMarks': 20,
                },
              },
      };
      final auth = AuthProvider(account, fixtures.storage)
        ..user = {'role': 'STUDENT'};
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AssignmentScreen(id: 'returned-assignment'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.enabled, status != 'GRADED');
      expect(
        find.text('Instructor feedback: Review the final section.'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      if (status == 'GRADED') {
        expect(
          find.text('This submission has been graded. Editing is closed.'),
          findsOneWidget,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
      } else {
        expect(find.text('Submit correction'), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      }
      expect(account.calls.every((call) => call.$1 == 'GET'), true);
    });
  }
  testWidgets(
    'notification mutations reload backend count and deletion requires confirmation',
    (tester) async {
      final account = fixtures.AdminAccount();
      var count = 2;
      var deleted = false;
      account.respond = (method, path, data) async {
        if (method == 'PATCH') count--;
        if (method == 'DELETE') {
          deleted = true;
          count = 0;
        }
        if (path.endsWith('/unread-count')) {
          return {
            'data': {'unreadCount': count},
          };
        }
        return {
          'data': {
            'notifications': deleted
                ? []
                : [
                    {
                      '_id': 'returned-notification',
                      'title': 'Feedback ready',
                      'message': 'Open your assignment.',
                      'isRead': count < 2,
                    },
                  ],
          },
        };
      };
      final auth = AuthProvider(account, fixtures.storage)
        ..user = {'role': 'STUDENT'};
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 unread'), findsOneWidget);
      await tester.tap(find.text('Feedback ready'));
      await tester.pumpAndSettle();
      expect(find.text('1 unread'), findsOneWidget);
      expect(
        account.calls.any(
          (call) =>
              call.$2 == '/api/v1/notifications/returned-notification/read',
        ),
        true,
      );
      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();
      expect(find.text('0 unread'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete notification'));
      await tester.pumpAndSettle();
      expect(deleted, false);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleted, false);
      await tester.tap(find.byTooltip('Delete notification'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(deleted, true);
      expect(find.text('0 unread'), findsOneWidget);
      expect(find.text('Feedback ready'), findsNothing);
    },
  );
  for (final status in [401, 403, 404, 422, 500]) {
    test('HTTP $status preserves status and provides a readable error', () {
      final request = RequestOptions(path: '/api/v1/courses/returned-course');
      final error = ApiException.fromDio(
        DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: status,
            data: {
              'message': 'Request denied',
              'details': [
                {'field': 'firstName'},
              ],
            },
          ),
        ),
      );
      expect(error.statusCode, status);
      expect(
        error.message,
        status == 500
            ? contains('try again later')
            : status == 422
            ? contains('first name')
            : 'Request denied',
      );
    });
  }
}

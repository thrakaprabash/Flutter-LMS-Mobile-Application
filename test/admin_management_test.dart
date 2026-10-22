import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/admin/services/admin_service.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/features/admin/screens/admin_list_screen.dart';
import 'package:flutter_lms/features/admin/dashboard/screens/admin_home_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_home_screen.dart';
import 'package:flutter_lms/features/student/dashboard/screens/student_home_screen.dart';

const storage = TokenStorage(FlutterSecureStorage());

class AdminAccount extends AccountService {
  AdminAccount() : super(ApiClient(storage));
  final calls = <(String, String, Object?)>[];
  Future<Map<String, dynamic>> Function(String, String, Object?)? respond;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    ProgressCallback? progress,
  }) async {
    expect(public, false);
    calls.add((method, path, data));
    if (respond != null) return respond!(method, path, data);
    return {
      'data': {
        'users': [
          {
            '_id': 'user-one',
            'firstName': 'Learner',
            'email': 'learner@example.test',
            'role': 'STUDENT',
            'status': 'ACTIVE',
          },
        ],
        'categories': [],
        'courses': [],
        'enrollments': [],
        'reviews': [],
        'pagination': {'page': 1, 'totalPages': 1},
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AdminAccount account;
  late AuthProvider auth;
  late AdminService service;
  setUp(() {
    account = AdminAccount();
    auth = AuthProvider(account, storage)
      ..user = {'_id': 'admin-self', 'role': 'ADMIN'};
    service = AdminService(auth);
  });
  tearDown(() => auth.dispose());

  test(
    'non-admin roles and revoked sessions cannot send admin requests',
    () async {
      for (final role in ['STUDENT', 'INSTRUCTOR', null]) {
        auth.user = role == null ? null : {'role': role};
        expect(
          () => service.request(
            'PATCH',
            'users/user-one/status',
            data: {'status': 'SUSPENDED'},
          ),
          throwsStateError,
        );
      }
      expect(account.calls, isEmpty);
    },
  );

  test(
    'list endpoints encode filters and include inactive categories',
    () async {
      await service.list('users', 2, {'search': 'A & B', 'role': 'STUDENT'});
      final uri = Uri.parse(account.calls.last.$2);
      expect(uri.path, '/api/v1/users');
      expect(uri.queryParameters, containsPair('search', 'A & B'));
      expect(uri.queryParameters['page'], '2');
      await service.list('categories', 1, {});
      expect(
        Uri.parse(account.calls.last.$2).queryParameters['activeOnly'],
        'false',
      );
      await service.list('courses', 1, {'status': 'DRAFT'});
      expect(account.calls.last.$2, contains('/courses/admin/all?'));
      await service.list('enrollments', 1, {'courseId': 'course-one'});
      expect(account.calls.last.$2, contains('/enrollments/admin/all?'));
      await service.list('reviews', 1, {}, courseId: 'course-one');
      expect(account.calls.last.$2, contains('/courses/course-one/reviews?'));
    },
  );

  test(
    'duplicate loads coalesce and stale filter responses are ignored',
    () async {
      final first = Completer<Map<String, dynamic>>();
      account.respond = (_, path, _) async {
        if (!path.contains('search=')) return first.future;
        return {
          'data': {
            'users': [
              {'_id': 'new'},
            ],
          },
        };
      };
      final state = AdminProvider(service, 'users');
      final pending = state.load();
      await state.load();
      expect(account.calls.length, 1);
      await state.filter('search', 'new');
      first.complete({
        'data': {
          'users': [
            {'_id': 'old'},
          ],
        },
      });
      await pending;
      expect(state.items.single['_id'], 'new');
      expect(state.loading, false);
      state.dispose();
    },
  );

  test(
    'pagination appends and failed next page preserves loaded rows',
    () async {
      var fail = false;
      account.respond = (_, path, _) async {
        if (fail) throw StateError('Unavailable');
        final page = int.parse(Uri.parse(path).queryParameters['page']!);
        return {
          'data': {
            'users': [
              {'_id': 'user-$page'},
            ],
            'pagination': {'page': page, 'totalPages': 3},
          },
        };
      };
      final state = AdminProvider(service, 'users');
      await state.load();
      await state.load(more: true);
      expect(state.items.length, 2);
      fail = true;
      await state.load(more: true);
      expect(state.items.length, 2);
      expect(state.page, 2);
      expect(state.error, isNotNull);
      expect(state.loading, false);
      state.dispose();
    },
  );

  test('failed mutation preserves data and exposes an error', () async {
    final state = AdminProvider(service, 'users');
    await state.load();
    account.respond = (_, _, _) async => throw StateError('Forbidden');
    expect(
      await state.mutate(
        'PATCH',
        'users/user-one/status',
        data: {'status': 'SUSPENDED'},
      ),
      false,
    );
    expect(state.items.single['status'], 'ACTIVE');
    expect(state.saving, false);
    expect(state.error, isNotNull);
    state.dispose();
  });

  test(
    'mutation locks repeated taps and reloads only after server success',
    () async {
      final pending = Completer<Map<String, dynamic>>();
      account.respond = (method, _, _) async => method == 'PATCH'
          ? pending.future
          : {
              'data': {'categories': []},
            };
      final state = AdminProvider(service, 'categories');
      final save = state.mutate(
        'PATCH',
        'categories/category-one/status',
        data: {'isActive': false},
      );
      expect(
        await state.mutate('PATCH', 'categories/category-one/status'),
        false,
      );
      expect(account.calls.length, 1);
      pending.complete({
        'data': {'isActive': false},
      });
      expect(await save, true);
      expect(account.calls.length, 2);
      expect(account.calls.first.$3, {'isActive': false});
      state.dispose();
    },
  );

  Future<void> mount(WidgetTester tester, Widget child) => tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(home: child),
    ),
  );

  testWidgets('wrong role cannot view or load admin lists', (tester) async {
    auth.user = {'role': 'STUDENT'};
    await mount(tester, const AdminListScreen(feature: 'users'));
    await tester.pumpAndSettle();
    expect(find.text('Administrator access required.'), findsOneWidget);
    expect(account.calls, isEmpty);
  });

  testWidgets(
    'suspension requires confirmation and sends exact status payload',
    (tester) async {
      await mount(tester, const AdminListScreen(feature: 'users'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suspend'));
      await tester.pumpAndSettle();
      expect(account.calls.where((c) => c.$1 == 'PATCH'), isEmpty);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final call = account.calls.where((c) => c.$1 == 'PATCH').single;
      expect(call.$1, 'PATCH');
      expect(call.$2, '/api/v1/users/user-one/status');
      expect(call.$3, {'status': 'SUSPENDED'});
    },
  );

  testWidgets('admin tabs preserve loaded users without duplicate requests', (
    tester,
  ) async {
    await mount(tester, const AdminHomeScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Platform'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();
    expect(
      account.calls.where((c) => c.$2.startsWith('/api/v1/users?')).length,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('review can be hidden and restored within the session', (
    tester,
  ) async {
    var visible = true;
    account.respond = (method, path, data) async {
      if (method == 'PATCH') {
        expect(path, '/api/v1/reviews/review-one/visibility');
        visible = (data as Map)['isVisible'] as bool;
        return {
          'data': {'isVisible': visible},
        };
      }
      return {
        'data': {
          'reviews': [
            if (visible)
              {
                '_id': 'review-one',
                'comment': 'Helpful lessons',
                'rating': 4,
                'isVisible': true,
              },
          ],
        },
      };
    };
    await mount(
      tester,
      const AdminListScreen(feature: 'reviews', courseId: 'course-one'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(visible, false);
    expect(find.text('Show review'), findsOneWidget);
    await tester.tap(find.text('Show review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(visible, true);
    expect(find.text('Hide review'), findsOneWidget);
  });

  testWidgets('category form validates before sending a real API payload', (
    tester,
  ) async {
    await mount(tester, const AdminListScreen(feature: 'categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(account.calls.where((c) => c.$1 == 'POST'), isEmpty);
    await tester.enterText(find.byType(TextFormField).at(0), 'Development');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Software development courses',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final call = account.calls.where((c) => c.$1 == 'POST').single;
    expect(call.$2, '/api/v1/categories');
    expect(call.$3, {
      'name': 'Development',
      'description': 'Software development courses',
    });
  });

  testWidgets('archive uses the administrator endpoint after confirmation', (
    tester,
  ) async {
    var status = 'DRAFT';
    account.respond = (method, path, data) async {
      if (method == 'PATCH') {
        expect(path, '/api/v1/courses/course-one/admin/archive');
        expect(data, isNull);
        status = 'ARCHIVED';
      }
      return {
        'data': {
          'courses': [
            {'_id': 'course-one', 'title': 'A course', 'status': status},
          ],
        },
      };
    };
    await mount(tester, const AdminListScreen(feature: 'courses'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Archive'));
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(status, 'DRAFT');
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
  });

  testWidgets('student tabs preserve data without repeat requests', (
    tester,
  ) async {
    auth.user = {'role': 'STUDENT'};
    await mount(tester, const StudentHomeScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    final before = account.calls.length;
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(account.calls.length, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('instructor tabs preserve data without repeat requests', (
    tester,
  ) async {
    auth.user = {'role': 'INSTRUCTOR'};
    await mount(tester, const InstructorHomeScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    final before = account.calls.length;
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courses'));
    await tester.pumpAndSettle();
    expect(account.calls.length, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin screens fit narrow displays with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final feature in ['users', 'categories', 'courses', 'enrollments']) {
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
            home: AdminListScreen(key: ValueKey(feature), feature: feature),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: feature);
    }
  });
}

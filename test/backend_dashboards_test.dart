import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/admin/dashboard/screens/admin_home_screen.dart';
import 'package:flutter_lms/features/instructor/screens/instructor_home_screen.dart';
import 'package:flutter_lms/features/student/dashboard/screens/student_home_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

import 'core_api_test.dart' show FakeAdapter, body;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final role in ['STUDENT', 'INSTRUCTOR', 'ADMIN']) {
    testWidgets(
      '$role dashboard uses authenticated API without a role picker',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        const storage = TokenStorage(FlutterSecureStorage());
        await storage.saveSession(
          accessToken: 'test-access',
          refreshToken: 'test-refresh',
          role: role,
        );
        final client = ApiClient(storage);
        final calls = <String>[];
        client.dio.httpClientAdapter = FakeAdapter((request) {
          calls.add(request.uri.path);
          expect(request.headers['Authorization'], 'Bearer test-access');
          if (request.uri.path == '/api/v1/dashboard/admin') {
            return body(200, {
              'data': {'totalUsers': 21, 'totalCourses': 4},
            });
          }
          if (request.uri.path == '/api/v1/dashboard/instructor') {
            return body(200, {
              'data': {'totalCourses': 4, 'totalEnrollments': 2},
            });
          }
          if (request.uri.path.endsWith('unread-count')) {
            return body(200, {
              'data': {'unreadCount': 0},
            });
          }
          return body(200, {
            'data': {
              'courses': [],
              'enrollments': [],
              'pagination': {'hasNextPage': false},
            },
          });
        });
        final auth = AuthProvider(AccountService(client), storage)
          ..user = {'role': role, 'firstName': 'Test'};
        addTearDown(auth.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: MaterialApp(
              home: switch (role) {
                'ADMIN' => const AdminHomeScreen(),
                'INSTRUCTOR' => const InstructorHomeScreen(),
                _ => const StudentHomeScreen(),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          calls,
          contains(switch (role) {
            'ADMIN' => '/api/v1/dashboard/admin',
            'INSTRUCTOR' => '/api/v1/dashboard/instructor',
            _ => '/api/v1/enrollments/me',
          }),
        );
        if (role == 'ADMIN') expect(find.text('21'), findsOneWidget);
        expect(find.textContaining('Sample data'), findsNothing);
        expect(find.text('Explore viva demo'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

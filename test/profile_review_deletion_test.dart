import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';
import 'package:flutter_lms/features/profile/screens/profile_screen.dart';
import 'package:flutter_lms/features/student/reviews/screens/reviews_screen.dart';

import 'instructor_management_test.dart' as fixtures;

class DeletionAccount extends AccountService {
  DeletionAccount(this.role, {this.fail = false})
    : super(ApiClient(fixtures.storage));
  final String role;
  final bool fail;
  bool deleted = false;
  final calls = <String>[];
  Map<String, dynamic> get user => {
    '_id': 'returned-user',
    'role': role,
    'firstName': 'Test',
    'lastName': 'User',
  };
  @override
  Future<Map<String, dynamic>> fullProfile() async => {
    'user': user,
    'profile': deleted
        ? null
        : {'educationLevel': 'School', 'headline': 'Teacher'},
  };
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    ProgressCallback? progress,
  }) async {
    if (method == 'DELETE') {
      calls.add(path);
      if (fail) throw const FormatException('Rejected');
      deleted = true;
      return {'data': {}};
    }
    return {
      'data': {
        'reviews': deleted
            ? []
            : [
                {
                  '_id': 'returned-review',
                  'studentId': 'returned-user',
                  'rating': 4,
                  'comment': 'Helpful',
                },
              ],
        'pagination': {'page': 1, 'totalPages': 1},
      },
    };
  }
}

void main() {
  testWidgets('admin profile has no deletion or deactivation controls', (
    tester,
  ) async {
    final account = DeletionAccount('ADMIN');
    final auth = AuthProvider(account, fixtures.storage)..user = account.user;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log out all devices'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Deactivate account'), findsNothing);
    expect(find.text('Delete profile details'), findsNothing);
    expect(account.calls, isEmpty);
  });
  for (final role in ['STUDENT', 'INSTRUCTOR']) {
    testWidgets(
      '$role profile deletion preserves account and clears role details',
      (tester) async {
        final account = DeletionAccount(role);
        final auth = AuthProvider(account, fixtures.storage)
          ..user = account.user;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: auth,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();
        final control = find.text('Delete profile details');
        await tester.scrollUntilVisible(
          control,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.ensureVisible(control);
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(account.calls, isEmpty);
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.ensureVisible(control);
        await tester.tap(control);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();
        expect(account.calls, ['/api/v1/profiles/${role.toLowerCase()}/me']);
        expect(auth.authenticated, true);
        expect(auth.profile, isNull);
        expect(find.text('Delete profile details'), findsNothing);
        expect(find.text('Deactivate account'), findsOneWidget);
      },
    );
  }
  for (final fail in [false, true]) {
    testWidgets('review deletion refreshes only on success, failure=$fail', (
      tester,
    ) async {
      final account = DeletionAccount('STUDENT', fail: fail);
      final auth = AuthProvider(account, fixtures.storage)..user = account.user;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: const MaterialApp(
            home: ReviewsScreen(courseId: 'returned-course', eligible: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final control = find.text('Delete my review');
      await tester.scrollUntilVisible(
        control,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(account.calls, isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(account.calls, ['/api/v1/reviews/returned-review']);
      expect(account.deleted, !fail);
      expect(control, fail ? findsOneWidget : findsNothing);
    });
  }
}

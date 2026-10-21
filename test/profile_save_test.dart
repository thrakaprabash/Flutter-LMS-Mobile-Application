import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/features/profile/screens/profile_screen.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

class SaveService extends AccountService {
  SaveService(super.client, this.fail);
  final bool fail;
  final user = <String, dynamic>{
    'id': 'user',
    'role': 'STUDENT',
    'firstName': 'Test',
    'lastName': 'User',
    'email': 'test@example.com',
  };
  final profile = <String, dynamic>{
    'learningGoals': ['Learn Flutter', 'Build mobile apps'],
    'educationLevel': 'Undergraduate',
  };
  @override
  Future<Map<String, dynamic>> fullProfile() async => {
    'user': {...user},
    'profile': {...profile},
  };
  final writes = <String>[];
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    dynamic progress,
  }) async {
    if (method == 'PATCH') {
      writes.add(path);
      if (fail && path.contains('/profiles/')) {
        throw const FormatException('Test failure');
      }
    }
    if (method == 'PATCH' && data is Map) {
      if (path.contains('/profiles/')) {
        profile.addAll(Map<String, dynamic>.from(data));
      } else {
        user.addAll(Map<String, dynamic>.from(data));
      }
    }
    return {'data': {}};
  }
}

void main() {
  for (final fail in [false, true]) {
    testWidgets('combined save handles role failure=$fail', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = TokenStorage(FlutterSecureStorage());
      final service = SaveService(ApiClient(storage), fail);
      final auth = AuthProvider(service, storage);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
        ),
      );
      await tester.pumpAndSettle();
      final firstName = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'First name',
      );
      await tester.ensureVisible(firstName);
      await tester.enterText(firstName, 'Updated');
      final goals = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Learning goals',
      );
      await tester.ensureVisible(goals);
      await tester.enterText(goals, 'New goal');
      await tester.ensureVisible(find.text('Save changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(service.writes, [
        '/api/v1/users/me',
        '/api/v1/profiles/student/me',
      ]);
      expect(auth.user?['firstName'], 'Updated');
      expect(
        service.profile['learningGoals'],
        fail ? ['Learn Flutter', 'Build mobile apps'] : ['New goal'],
      );
      if (fail) {
        expect(tester.widget<TextField>(goals).controller!.text, 'New goal');
        await tester.scrollUntilVisible(
          find.text('Save changes'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(service.writes.where((p) => p == '/api/v1/users/me').length, 1);
      }
      auth.dispose();
    });
  }
}

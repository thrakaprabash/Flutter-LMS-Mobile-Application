import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/demo/demo_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('demo profile edits and logout preserve real secure credentials', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = TokenStorage(FlutterSecureStorage());
    await storage.saveSession(accessToken: 'real-access', refreshToken: 'real-refresh', role: 'STUDENT');
    final service = DemoAccountService(ApiClient(storage), 'STUDENT');
    final demo = DemoAuthProvider(service, storage);
    await service.request('PATCH', '/api/v1/users/me', data: {'firstName': 'Updated'});
    await demo.loadProfile();
    expect(demo.user?['firstName'], 'Updated');
    await expectLater(service.request('POST', '/api/v1/auth/login'), throwsFormatException);
    await demo.logout();
    expect(await storage.readAccessToken(), 'real-access');
    expect(await storage.readRefreshToken(), 'real-refresh');
    final fresh = DemoAccountService(ApiClient(storage), 'STUDENT');
    expect(fresh.user['firstName'], 'Alex');
    demo.dispose();
  });
}

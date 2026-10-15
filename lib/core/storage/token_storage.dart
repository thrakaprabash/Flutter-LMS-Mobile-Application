import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class TokenStorage {
  const TokenStorage(this.storage);
  final FlutterSecureStorage storage;
  Future<String?> readAccessToken() =>
      storage.read(key: StorageKeys.accessToken);
  Future<String?> readRefreshToken() =>
      storage.read(key: StorageKeys.refreshToken);
  Future<String?> readRole() => storage.read(key: StorageKeys.role);
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    try {
      await storage.write(key: StorageKeys.accessToken, value: accessToken);
      await storage.write(key: StorageKeys.refreshToken, value: refreshToken);
      await storage.write(key: StorageKeys.role, value: role);
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    await Future.wait(
      [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.role,
      ].map((key) => storage.delete(key: key)),
    );
  }
}

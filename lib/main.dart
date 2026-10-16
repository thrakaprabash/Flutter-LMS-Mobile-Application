import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/services/account_service.dart';
import 'shared/providers/auth_provider.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
  late AuthProvider auth;
  final client = ApiClient(
    storage,
    onSessionExpired: () {
      auth.invalidate();
    },
  );
  final service = AccountService(client);
  auth = AuthProvider(service, storage);
  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: storage),
        Provider<ApiClient>.value(value: client),
        Provider<AccountService>.value(value: service),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: const LmsApp(),
    ),
  );
}

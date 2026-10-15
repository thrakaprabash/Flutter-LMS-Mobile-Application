import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = TokenStorage(FlutterSecureStorage());
  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: storage),
        Provider<ApiClient>(create: (_) => ApiClient(storage)),
      ],
      child: const LmsApp(),
    ),
  );
}

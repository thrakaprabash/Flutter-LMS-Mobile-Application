import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/app.dart';
import 'package:flutter_lms/core/network/api_client.dart';
import 'package:flutter_lms/core/storage/token_storage.dart';
import 'package:flutter_lms/features/auth/services/account_service.dart';
import 'package:flutter_lms/shared/providers/auth_provider.dart';

Widget testApp({String initialRoute = '/splash', AuthProvider? auth}) {
  FlutterSecureStorage.setMockInitialValues({});
  const storage = TokenStorage(FlutterSecureStorage());
  auth ??= AuthProvider(AccountService(ApiClient(storage)), storage);
  if (initialRoute != '/' && initialRoute != '/splash') {
    auth.user = {
      'role': initialRoute.substring(1).toUpperCase(),
      'email': 'test@example.com',
    };
  }
  return ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: LmsApp(initialRoute: initialRoute),
  );
}

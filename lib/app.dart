import 'package:flutter/material.dart';

import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';

class LmsApp extends StatelessWidget {
  const LmsApp({super.key, this.initialRoute = AppRoutes.splash});
  final String initialRoute;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter LMS',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    initialRoute: initialRoute,
    routes: AppRoutes.routes,
  );
}

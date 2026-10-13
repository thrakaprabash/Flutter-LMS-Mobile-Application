import 'package:flutter/material.dart';

import 'core/routing/route_names.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class LmsApp extends StatelessWidget {
  const LmsApp({super.key, this.initialRoute = RouteNames.splash});
  final String initialRoute;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter LMS',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    initialRoute: initialRoute,
    routes: AppRouter.routes,
  );
}

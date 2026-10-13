import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/entry_screens.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/data/dashboard_data.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/';
  static const home = '/home';
  static const onboarding = '/onboarding';
  static const student = '/student';
  static const instructor = '/instructor';
  static const admin = '/admin';
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    onboarding: (_) => const OnboardingScreen(),
    student: (_) => const DashboardScreen(role: LmsRole.student),
    instructor: (_) => const DashboardScreen(role: LmsRole.instructor),
    admin: (_) => const DashboardScreen(role: LmsRole.admin),
  };
}

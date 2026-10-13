import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/entry_screens.dart';
import '../../features/student/dashboard/screens/student_home_screen.dart';
import '../../features/instructor/dashboard/screens/instructor_home_screen.dart';
import '../../features/admin/dashboard/screens/admin_home_screen.dart';
import 'route_names.dart';

/// Day 3 preview routes. Backend role authorization belongs to later days.
abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.home: (_) => const HomeScreen(),
    RouteNames.onboarding: (_) => const OnboardingScreen(),
    RouteNames.student: (_) => const StudentHomeScreen(),
    RouteNames.instructor: (_) => const InstructorHomeScreen(),
    RouteNames.admin: (_) => const AdminHomeScreen(),
  };
}

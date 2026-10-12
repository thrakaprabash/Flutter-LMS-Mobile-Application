import 'package:flutter/material.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../shared/widgets/route_placeholder_screen.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const home = '/home';
  static const onboarding = '/onboarding';
  static const student = '/student';
  static const instructor = '/instructor';
  static const admin = '/admin';
  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    onboarding: (_) => const RoutePlaceholderScreen(title: 'Onboarding'),
    student: (_) => const RoutePlaceholderScreen(title: 'Student dashboard'),
    instructor: (_) =>
        const RoutePlaceholderScreen(title: 'Instructor dashboard'),
    admin: (_) => const RoutePlaceholderScreen(title: 'Admin dashboard'),
  };
}

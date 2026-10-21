import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/providers/auth_provider.dart';

import '../../features/auth/screens/login_screen.dart';

import '../../features/onboarding/screens/entry_screens.dart';
import '../../features/student/dashboard/screens/student_home_screen.dart';
import '../../features/instructor/screens/instructor_home_screen.dart';
import '../../features/admin/dashboard/screens/admin_home_screen.dart';
import 'route_names.dart';

/// Protected routes use only the backend-authenticated role.
abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    RouteNames.splash: (_) => const SplashScreen(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.home: (_) => const ProtectedScreen(child: SizedBox.shrink()),
    RouteNames.onboarding: (_) => const OnboardingScreen(),
    RouteNames.student: (_) =>
        const ProtectedScreen(role: 'STUDENT', child: StudentHomeScreen()),
    RouteNames.instructor: (_) => const ProtectedScreen(
      role: 'INSTRUCTOR',
      child: InstructorHomeScreen(),
    ),
    RouteNames.admin: (_) =>
        const ProtectedScreen(role: 'ADMIN', child: AdminHomeScreen()),
  };
}

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key, this.role, required this.child});
  final String? role;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated ||
        (role != null && role != auth.role) ||
        role == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, auth.route, (_) => false);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}

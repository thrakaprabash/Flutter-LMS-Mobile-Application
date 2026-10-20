import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' show FormData;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/token_storage.dart';
import '../../shared/providers/auth_provider.dart';
import '../auth/services/account_service.dart';
import '../student/dashboard/screens/student_home_screen.dart';
import '../instructor/screens/instructor_home_screen.dart';
import '../admin/dashboard/screens/admin_home_screen.dart';
import 'demo_activity_data.dart';
import 'demo_instructor_data.dart';

/// An isolated in-memory account service. Never forwards requests to Dio.
class DemoAccountService extends AccountService {
  DemoAccountService(super.client, String role) {
    user = {
      'id': 'demo-user',
      'firstName': 'Alex',
      'lastName': 'Taylor',
      'email': 'alex@example.com',
      'role': role,
      'bio': 'Exploring Flutter LMS in demo mode.',
      'profileImageUrl': null,
    };
    profile = role == 'STUDENT'
        ? {
            'dateOfBirth': '2002-04-04',
            'educationLevel': 'Undergraduate',
            'learningGoals': ['Learn Flutter', 'Build mobile apps'],
          }
        : role == 'INSTRUCTOR'
        ? {
            'headline': 'Mobile application instructor',
            'qualification': 'BSc in Software Engineering',
            'experienceYears': 5,
            'expertise': ['Flutter', 'Dart'],
            'biography': 'Helping learners build practical skills.',
          }
        : null;
  }
  late Map<String, dynamic> user;
  Map<String, dynamic>? profile;
  final activity = DemoActivityData();
  final instructorData = DemoInstructorData();
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Object? data,
    bool public = false,
    dynamic progress,
  }) async {
    if (method == 'GET' && path == '/api/v1/users/me/full-profile') {
      return {
        'data': {
          'user': Map<String, dynamic>.from(user),
          'profile': profile == null
              ? null
              : Map<String, dynamic>.from(profile!),
        },
      };
    }
    if (method == 'PATCH' &&
        path == '/api/v1/users/me' &&
        data is Map<String, dynamic>) {
      user.addAll(data);
      return {'message': 'Demo account saved locally.'};
    }
    if (['PATCH', 'POST'].contains(method) &&
        path ==
            '/api/v1/profiles/${user['role'].toString().toLowerCase()}/me' &&
        data is Map<String, dynamic>) {
      profile = {...?profile, ...data};
      return {'message': 'Demo profile saved locally.'};
    }
    if (user['role'] == 'INSTRUCTOR') {
      if (data is FormData && progress != null) {
        progress(0, 100);
        await Future<void>.delayed(const Duration(milliseconds: 180));
        progress(50, 100);
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      final sample = instructorData.handle(
        method,
        path,
        data,
        progress: progress,
      );
      if (sample != null) return sample;
      throw const FormatException(
        'This action is unavailable in instructor demo mode.',
      );
    }
    final sample = activity.handle(method, path, data);
    if (sample != null) return sample;
    // Media, authentication and other APIs deliberately have no demo transport.
    throw const FormatException('This action is unavailable in demo mode.');
  }
}

class DemoAuthProvider extends AuthProvider {
  @override
  bool get isDemo => true;
  DemoAuthProvider(DemoAccountService service, TokenStorage storage)
    : super(service, storage) {
    user = Map<String, dynamic>.from(service.user);
    profile = service.profile == null
        ? null
        : Map<String, dynamic>.from(service.profile!);
  }
  @override
  Future<void> invalidate() async {
    user = null;
    profile = null;
    notifyListeners();
  }

  @override
  Future<void> logout({bool all = false}) => invalidate();
  @override
  Future<void> accept(Map<String, dynamic> response) async =>
      throw UnsupportedError('Demo mode has no authentication.');
  @override
  Future<void> restore() async => loadProfile();
}

class DemoPickerScreen extends StatelessWidget {
  const DemoPickerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('Demo is available only in development builds.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Viva demo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Explore the app',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Sample accounts only. Changes stay in memory and reset with a new demo session. Instructor course building, quizzes and grading work locally; media uploads are simulated. Real account actions require backend login.',
              ),
              const SizedBox(height: 24),
              for (final role in ['STUDENT', 'INSTRUCTOR', 'ADMIN'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    icon: Icon(
                      role == 'STUDENT'
                          ? Icons.school_outlined
                          : role == 'INSTRUCTOR'
                          ? Icons.menu_book_outlined
                          : Icons.admin_panel_settings_outlined,
                    ),
                    label: Text(
                      '${role[0]}${role.substring(1).toLowerCase()} demo',
                    ),
                    onPressed: () {
                      final realAuth = context.read<AuthProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChangeNotifierProvider<AuthProvider>(
                            create: (_) => DemoAuthProvider(
                              DemoAccountService(realAuth.service.client, role),
                              realAuth.storage,
                            ),
                            child: _DemoDashboard(role: role),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoDashboard extends StatelessWidget {
  const _DemoDashboard({required this.role});
  final String role;
  @override
  Widget build(BuildContext context) => role == 'INSTRUCTOR'
      ? const InstructorHomeScreen()
      : Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'DEMO · Sample data · Local edits only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Exit demo'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (role) {
                    'STUDENT' => const StudentHomeScreen(),
                    'INSTRUCTOR' => const InstructorHomeScreen(),
                    _ => const AdminHomeScreen(),
                  },
                ),
              ],
            ),
          ),
        );
}

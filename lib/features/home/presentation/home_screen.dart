import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'Explore Flutter LMS',
                subtitle:
                    'Preview the routes prepared for your learning platform.',
              ),
              const SizedBox(height: 20),
              const AppMessage(
                message: 'Local preview only. Your inputs passed validation; no account has been authenticated. Role access will come from the backend later.',
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    for (final entry in const {
                      'Onboarding': AppRoutes.onboarding,
                      'Student dashboard': AppRoutes.student,
                      'Instructor dashboard': AppRoutes.instructor,
                      'Admin dashboard': AppRoutes.admin,
                    }.entries)
                      ListTile(
                        title: Text(entry.key),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, entry.value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Back to login',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

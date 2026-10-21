import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/auth_provider.dart';
import 'services/learning_service.dart';

Widget learningScope(BuildContext context, Widget child) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: context.read<AuthProvider>(),
      child: Provider<LearningService>.value(
        value: context.read<LearningService>(),
        child: _LearningAccess(child: child),
      ),
    );

class _LearningAccess extends StatelessWidget {
  const _LearningAccess({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'STUDENT') {
      return const Scaffold(
        body: Center(child: Text('Sign in as a student to continue.')),
      );
    }
    return child;
  }
}

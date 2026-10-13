import 'package:flutter/material.dart';
import 'package:flutter_lms/shared/models/dashboard_models.dart';
import 'package:flutter_lms/shared/widgets/dashboard_shell.dart';

import '../models/instructor_dashboard_preview.dart';

class InstructorHomeScreen extends StatelessWidget {
  const InstructorHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DashboardShell(
    role: LmsRole.instructor,
    data: InstructorDashboardPreview.summary,
    management: InstructorDashboardPreview.management,
  );
}

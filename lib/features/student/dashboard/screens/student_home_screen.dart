import 'package:flutter/material.dart';
import 'package:flutter_lms/shared/models/dashboard_models.dart';
import 'package:flutter_lms/shared/widgets/dashboard_shell.dart';

import '../models/student_dashboard_preview.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DashboardShell(
    role: LmsRole.student,
    data: StudentDashboardPreview.summary,
    courses: StudentDashboardPreview.courses,
    deadlines: StudentDashboardPreview.deadlines,
  );
}

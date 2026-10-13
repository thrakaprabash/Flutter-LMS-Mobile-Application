import 'package:flutter/material.dart';
import 'package:flutter_lms/shared/models/dashboard_models.dart';
import 'package:flutter_lms/shared/widgets/dashboard_shell.dart';

import '../models/admin_dashboard_preview.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DashboardShell(
    role: LmsRole.admin,
    data: AdminDashboardPreview.summary,
    management: AdminDashboardPreview.management,
  );
}

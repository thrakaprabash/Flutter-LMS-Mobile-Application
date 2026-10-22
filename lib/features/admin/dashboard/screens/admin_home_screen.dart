import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/learning_page.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../profile/screens/profile_screen.dart';
import '../../screens/admin_list_screen.dart';
import '../../widgets/admin_ui.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int tab = 0;
  final visited = <int>{0};
  Map<String, dynamic> summary = {};
  bool busy = true;
  bool _loading = false;
  String? error;
  void select(int index) {
    if (index == tab) return;
    setState(() {
      tab = index;
      visited.add(index);
    });
    if (index == 0) load();
  }

  Future<void> open(String feature) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AdminListScreen(feature: feature),
      ),
    );
    if (mounted) load();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    if (!mounted || _loading) return;
    final auth = context.read<AuthProvider>();
    if (!auth.authenticated || auth.role != 'ADMIN') return;
    _loading = true;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await auth.service.request(
        'GET',
        '/api/v1/dashboard/admin',
      );
      final data = object(response['data']);
      final dashboard = object(data['dashboard'] ?? data);
      if (mounted) {
        setState(
          () => summary = object(
            dashboard['summary'] ?? dashboard['stats'] ?? dashboard,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = AuthProvider.message(e));
    } finally {
      _loading = false;
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'ADMIN') {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    return Scaffold(
      backgroundColor: adminCanvas,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: adminLine)),
        ),
        child: NavigationBar(
          height: 76,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE5EEDC),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: tab,
          onDestinationSelected: select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded),
              label: 'Platform',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      appBar: tab == 1
          ? null
          : AppBar(
              backgroundColor: adminCanvas,
              surfaceTintColor: Colors.transparent,
              title: Text(
                [
                  'Admin workspace',
                  'Users',
                  'Platform management',
                  'My profile',
                ][tab],
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                if (tab == 0)
                  IconButton(
                    tooltip: 'Refresh dashboard',
                    onPressed: busy ? null : load,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
      body: IndexedStack(
        index: tab,
        children: [
          overview(),
          visited.contains(1)
              ? const AdminListScreen(feature: 'users')
              : const SizedBox.shrink(),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const AdminHeading(
                'A better learning platform.',
                subtitle: 'Keep your catalog organized and learning on track.',
              ),
              AdminShortcut(
                title: 'Course catalog',
                subtitle: 'Inspect drafts, published and archived courses',
                icon: adminIcon('courses'),
                onTap: () => open('courses'),
              ),
              AdminShortcut(
                title: 'Categories',
                subtitle: 'Organize the subjects learners discover',
                icon: adminIcon('categories'),
                onTap: () => open('categories'),
                color: const Color(0xFFA9783E),
              ),
              AdminShortcut(
                title: 'Enrollments',
                subtitle: 'Follow learner participation across courses',
                icon: adminIcon('enrollments'),
                onTap: () => open('enrollments'),
                color: const Color(0xFF5276A6),
              ),
              const SizedBox(height: 16),
              const AdminHeading(
                'Quality & moderation',
                subtitle: 'Thoughtful oversight for every course.',
              ),
              AdminShortcut(
                title: 'Course reviews',
                subtitle:
                    'Choose a course to review learner feedback and visibility',
                icon: adminIcon('reviews'),
                onTap: () => open('courses'),
                color: const Color(0xFF8B709C),
              ),
            ],
          ),
          visited.contains(3)
              ? ProfileScreen(
                  onSignedOut: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (_) => false,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget overview() => RefreshIndicator(
    onRefresh: load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        Text(
          'Welcome back${context.read<AuthProvider>().user?['firstName'] == null ? '' : ', ${context.read<AuthProvider>().user!['firstName']}'}',
          style: const TextStyle(color: adminMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your platform, in focus.',
          style: TextStyle(
            color: adminInk,
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF163F31), Color(0xFF326B4F)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFFD8E9BA),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'PLATFORM OVERVIEW',
                      style: TextStyle(
                        color: Color(0xFFD8E9BA),
                        letterSpacing: 1.4,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'A place for learning\nto thrive.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Support your people. Shape your catalog.\nKeep every learning journey moving.',
                style: TextStyle(
                  color: Color(0xFFCDDDCF),
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => select(1),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: const Color(0xFFE1EDCE),
                  foregroundColor: adminInk,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'LmsRoboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Manage people'),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: busy ? 20 : 0,
          padding: EdgeInsets.only(top: busy ? 16 : 0),
          child: busy ? const LinearProgressIndicator(minHeight: 3) : null,
        ),
        if (error != null)
          AdminNotice(
            error!,
            error: true,
            action: TextButton(onPressed: load, child: const Text('Retry')),
          ),
        const SizedBox(height: 24),
        const AdminHeading(
          'At a glance',
          subtitle: 'The latest totals across your learning community',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final single =
                constraints.maxWidth < 270 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final width = single
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in [
                  (
                    'totalStudents',
                    'Students',
                    Icons.people_outline_rounded,
                    const Color(0xFF227250),
                  ),
                  (
                    'totalInstructors',
                    'Instructors',
                    Icons.auto_stories_outlined,
                    const Color(0xFFA9783E),
                  ),
                  (
                    'totalEnrollments',
                    'Enrollments',
                    Icons.school_outlined,
                    const Color(0xFF5276A6),
                  ),
                  (
                    'publishedCourses',
                    'Published courses',
                    Icons.auto_stories_outlined,
                    const Color(0xFF8B709C),
                  ),
                  (
                    'activeUsers',
                    'Active users',
                    Icons.verified_user_outlined,
                    const Color(0xFF227250),
                  ),
                  (
                    'completedEnrollments',
                    'Completions',
                    Icons.task_alt_rounded,
                    const Color(0xFF5276A6),
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: AdminPanel(
                      padding: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(metric.$3, color: metric.$4, size: 22),
                          const SizedBox(height: 14),
                          Text(
                            summary[metric.$1] is num
                                ? '${summary[metric.$1]}'
                                : '—',
                            style: const TextStyle(
                              color: adminInk,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            metric.$2,
                            style: const TextStyle(
                              color: adminMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const AdminHeading(
          'Your workspace',
          subtitle: 'Everything you need to keep the platform running',
        ),
        AdminShortcut(
          title: 'People & access',
          subtitle: 'Manage accounts, roles and account status',
          icon: adminIcon('users'),
          onTap: () => select(1),
        ),
        AdminShortcut(
          title: 'Course catalog',
          subtitle: 'Oversee course content and learner reviews',
          icon: adminIcon('courses'),
          onTap: () => open('courses'),
          color: const Color(0xFFA9783E),
        ),
        AdminShortcut(
          title: 'Learning activity',
          subtitle: 'Explore enrollments across your platform',
          icon: adminIcon('enrollments'),
          onTap: () => open('enrollments'),
          color: const Color(0xFF5276A6),
        ),
      ],
    ),
  );
}

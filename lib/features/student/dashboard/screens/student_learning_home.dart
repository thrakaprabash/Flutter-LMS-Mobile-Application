import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../profile/screens/profile_screen.dart';

import '../../learning/services/learning_service.dart';
import '../../courses/screens/course_list_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../widgets/student_ui.dart';

class StudentLearningHome extends StatelessWidget {
  const StudentLearningHome({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Provider<LearningService>(
      key: ObjectKey(auth),
      create: (_) => LearningService(auth.service),
      child: const _LearningHome(),
    );
  }
}

class _LearningHome extends StatefulWidget {
  const _LearningHome();
  @override
  State<_LearningHome> createState() => _LearningHomeState();
}

class _LearningHomeState extends State<_LearningHome> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        ['Learning space', 'Explore courses', 'My learning', 'My profile'][tab],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: studentInk,
        ),
      ),
      backgroundColor: const Color(0xFFF6F7F2),
      surfaceTintColor: Colors.transparent,
      actions: [
        const NotificationBell(),
        if (tab != 3)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'My profile',
              onPressed: () => setState(() => tab = 3),
              icon: Builder(
                builder: (context) {
                  final user = context.watch<AuthProvider>().user;
                  final name = '${user?['firstName'] ?? ''}'.trim();
                  final url = user?['profileImageUrl'];
                  final fallback = CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE3EBD9),
                    child: Text(
                      name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 13, color: studentInk),
                    ),
                  );
                  return SizedBox.square(
                    dimension: 36,
                    child: ClipOval(
                      child: url is String && url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, error, stack) => fallback,
                            )
                          : fallback,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE5EEDC),
      height: 76,
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Explore',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'My courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
    body: tab == 3
        ? ProfileScreen(
            onSignedOut: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
          )
        : CourseList(
            key: ValueKey(tab),
            mine: tab != 1,
            dashboard: tab == 0,
            onExplore: () => setState(() => tab = 1),
          ),
  );
}

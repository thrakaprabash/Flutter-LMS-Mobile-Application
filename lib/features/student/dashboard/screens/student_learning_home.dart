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
    if (!auth.authenticated || auth.role != 'STUDENT') {
      return const Scaffold(
        body: Center(child: Text('Student access required.')),
      );
    }
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
  final visited = <int>{0};
  void select(int index) => setState(() {
    tab = index;
    visited.add(index);
  });
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
              onPressed: () => select(3),
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
      onDestinationSelected: select,
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
    body: IndexedStack(
      index: tab,
      children: [
        for (var index = 0; index < 3; index++)
          visited.contains(index)
              ? CourseList(
                  key: ValueKey(index),
                  mine: index != 1,
                  dashboard: index == 0,
                  onExplore: () => select(1),
                )
              : const SizedBox.shrink(),
        visited.contains(3)
            ? ProfileScreen(
                onSignedOut: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
              )
            : const SizedBox.shrink(),
      ],
    ),
  );
}

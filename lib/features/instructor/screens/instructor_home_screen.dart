import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../widgets/instructor_widgets.dart';

import 'instructor_workspace.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});
  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  int tab = 0;
  void select(int index) => setState(() => tab = index);
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'INSTRUCTOR') {
      return const Scaffold(
        body: Center(child: Text('Instructor access required.')),
      );
    }
    return Scaffold(
      body: tab == 3
          ? SafeArea(
              bottom: false,
              child: ProfileScreen(
                onSignedOut: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                },
              ),
            )
          : InstructorWorkspace(
              key: ValueKey(tab),
              kind: ['home', 'courses', 'learners'][tab],
              onDestinationSelected: select,
            ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: studioLine)),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: select,
          height: 76,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE5EEDC),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Learners',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

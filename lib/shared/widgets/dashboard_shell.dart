import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/app_widgets.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.role,
    required this.data,
    this.courses = const [],
    this.deadlines = const [],
    this.management,
  }) : assert(role != LmsRole.student || courses.length > 0),
       assert(role == LmsRole.student || management != null);
  final LmsRole role;
  final DashboardData data;
  final List<CoursePreview> courses;
  final List<DeadlinePreview> deadlines;
  final ManagementPreview? management;
  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selected = 0;
  void _openShortcut(String title) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const EmptyState(
          title: 'Coming soon',
          message: 'This feature will be connected in a later task.',
        ),
      ),
    ),
  );

  Widget _heading(String title, {String? action, VoidCallback? onTap}) =>
      Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (action != null)
              TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      );

  Widget _courseCard(CoursePreview course, {bool featured = false}) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: featured ? colors.primary : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: featured ? Colors.white : colors.onSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: featured
                          ? Colors.white.withValues(alpha: 0.15)
                          : colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_outlined,
                      color: featured ? Colors.white : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      course.code,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text('${(course.progress * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(course.lesson),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: course.progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
                color: featured ? const Color(0xFFE5CB85) : colors.primary,
                backgroundColor: featured
                    ? Colors.white24
                    : colors.primaryContainer,
                semanticsLabel: '${course.title} progress',
              ),
              const SizedBox(height: 10),
              Text(
                '${course.completed} lessons completed · ${course.duration} min next lesson',
              ),
              const SizedBox(height: 18),
              if (featured)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colors.primary,
                  ),
                  onPressed: () => _openShortcut(course.title),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue lesson'),
                )
              else
                OutlinedButton(
                  onPressed: () => _openShortcut(course.title),
                  child: const Text('Open course'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _studentContent() => [
    _heading('Continue learning'),
    _courseCard(widget.courses.first, featured: true),
    _heading('Quick access'),
    LayoutBuilder(
      builder: (context, bounds) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in [
            (Icons.menu_book_outlined, 'My courses', 1),
            (Icons.assignment_outlined, 'Assignments', 2),
            (Icons.quiz_outlined, 'Quizzes', -1),
            (Icons.campaign_outlined, 'Announcements', -1),
          ])
            SizedBox(
              width: (bounds.maxWidth - 12) / 2,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    if (item.$3 >= 0) {
                      setState(() => _selected = item.$3);
                    } else {
                      _openShortcut(item.$2);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.$1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(item.$2),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    _heading(
      'Coming up',
      action: 'View assignments',
      onTap: () => setState(() => _selected = 2),
    ),
    _DashboardCard(
      child: Column(
        children: [
          for (var i = 0; i < widget.deadlines.length; i++) ...[
            if (i > 0) const Divider(height: 28),
            Builder(
              builder: (context) {
                final item = widget.deadlines[i];
                return InkWell(
                  onTap: () => _openShortcut(item.title),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2D6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.quiz
                                ? Icons.quiz_outlined
                                : Icons.assignment_outlined,
                            color: const Color(0xFF806018),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(item.course),
                              const SizedBox(height: 6),
                              Text(
                                item.due,
                                style: const TextStyle(
                                  color: Color(0xFF806018),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    ),
    _heading(
      'My courses',
      action: 'View all',
      onTap: () => setState(() => _selected = 1),
    ),
    for (final course in widget.courses.skip(1)) ...[
      _courseCard(course),
      const SizedBox(height: 12),
    ],
  ];

  Widget _quickActions(List<(IconData, String)> actions) => LayoutBuilder(
    builder: (context, bounds) => Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final action in actions)
          SizedBox(
            width: (bounds.maxWidth - 12) / 2,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _openShortcut(action.$2),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        action.$1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(action.$2),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  List<Widget> _managementContent(DashboardData data) {
    final instructor = widget.role == LmsRole.instructor;
    final preview = widget.management!;
    final colors = Theme.of(context).colorScheme;
    final icons = instructor
        ? [
            Icons.add_circle_outline,
            Icons.rate_review_outlined,
            Icons.groups_outlined,
            Icons.assignment_outlined,
          ]
        : [
            Icons.people_outline,
            Icons.category_outlined,
            Icons.menu_book_outlined,
            Icons.reviews_outlined,
          ];
    return [
      _heading(
        instructor ? 'Make a difference today' : 'Keep your campus connected',
      ),
      Card(
        color: colors.primary,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    instructor
                        ? Icons.rate_review_outlined
                        : Icons.verified_user_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                preview.focusTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                preview.focusMessage,
                style: const TextStyle(color: Colors.white, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.primary,
                ),
                onPressed: () => instructor
                    ? setState(() => _selected = 2)
                    : _openShortcut(preview.focusAction),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(preview.focusAction),
              ),
            ],
          ),
        ),
      ),
      _heading('Quick access'),
      _quickActions([
        for (var i = 0; i < preview.shortcuts.length; i++)
          (icons[i], preview.shortcuts[i]),
      ]),
      _heading(preview.queueTitle),
      _DashboardCard(
        child: Column(
          children: [
            for (var i = 0; i < preview.queue.length; i++) ...[
              if (i > 0) const Divider(height: 28),
              _actionRow(
                preview.queue[i],
                instructor ? Icons.assignment_outlined : Icons.shield_outlined,
                attention: true,
              ),
            ],
          ],
        ),
      ),
      _heading(instructor ? 'Teaching at a glance' : 'Campus at a glance'),
      LayoutBuilder(
        builder: (context, bounds) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in data.metrics)
              SizedBox(
                width: bounds.maxWidth < 500
                    ? bounds.maxWidth
                    : (bounds.maxWidth - 24) / 3,
                child: _DashboardCard(
                  child: Row(
                    children: [
                      Icon(
                        instructor
                            ? Icons.school_outlined
                            : Icons.insights_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.$2,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(metric.$1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      _heading(
        preview.collectionTitle,
        action: 'View all',
        onTap: () => instructor
            ? setState(() => _selected = 1)
            : _openShortcut('Platform overview'),
      ),
      for (final entry in preview.collection) ...[
        _DashboardCard(
          child: _actionRow(
            entry,
            instructor ? Icons.menu_book_outlined : Icons.groups_outlined,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _actionRow(
    (String, String, String) item,
    IconData icon, {
    bool attention = false,
  }) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => _openShortcut(item.$1),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: attention
                  ? const Color(0xFFFFF2D6)
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: attention
                  ? const Color(0xFF806018)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(item.$2),
                const SizedBox(height: 8),
                Text(
                  item.$3,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: attention
                        ? const Color(0xFF806018)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final student = widget.role == LmsRole.student;
    return Scaffold(
      appBar: AppBar(
        title: Text(data.title),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _openShortcut('Notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected,
        onDestinationSelected: (index) => setState(() => _selected = index),
        destinations: [
          for (var i = 0; i < data.destinations.length; i++)
            NavigationDestination(
              icon: Icon(
                [
                  Icons.home_outlined,
                  widget.role == LmsRole.admin
                      ? Icons.people_outline
                      : Icons.menu_book_outlined,
                  widget.role == LmsRole.admin
                      ? Icons.category_outlined
                      : Icons.assignment_outlined,
                  Icons.person_outline,
                ][i],
              ),
              label: data.destinations[i],
            ),
        ],
      ),
      body: SafeArea(
        child: _selected != 0
            ? EmptyState(
                title: data.destinations[_selected],
                message:
                    'Your ${data.destinations[_selected].toLowerCase()} will appear here once connected.',
                actionLabel: 'Back to overview',
                onAction: () => setState(() => _selected = 0),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      SectionHeader(
                        title: student
                            ? 'Ready for your next lesson?'
                            : data.greeting,
                        subtitle: student
                            ? 'Your courses, deadlines and next steps in one place.'
                            : data.subtitle,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Preview dashboard · Sample data',
                        style: TextStyle(fontSize: 12),
                      ),
                      if (student)
                        ..._studentContent()
                      else
                        ..._managementContent(data),
                      _heading('Recent activity'),
                      _DashboardCard(
                        child: Column(
                          children: [
                            for (final activity in data.activity)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.check_circle_outline),
                                title: Text(activity),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

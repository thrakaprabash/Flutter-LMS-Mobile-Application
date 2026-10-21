import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/learning_page.dart';
import '../../learning/widgets/learning_widgets.dart';
import '../../widgets/student_ui.dart';

class CourseListHeader extends StatelessWidget {
  const CourseListHeader({
    super.key,
    required this.mine,
    required this.dashboard,
    required this.busy,
    required this.search,
    required this.category,
    required this.status,
    required this.categories,
    required this.onSearch,
    required this.onClear,
    required this.onStatus,
    required this.onCategory,
    this.onExplore,
  });
  final bool mine, dashboard, busy;
  final TextEditingController search;
  final String category, status;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSearch, onClear;
  final VoidCallback? onExplore;
  final ValueChanged<String> onStatus, onCategory;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (dashboard) ...[
        Text(
          'Good to see you${'${context.watch<AuthProvider>().user?['firstName'] ?? ''}'.trim().isEmpty ? '' : ', ${context.watch<AuthProvider>().user?['firstName']}'}',
          style: const TextStyle(color: studentMuted),
        ),
        const SizedBox(height: 8),
        const StudentHeading('A little learning, every day.'),
        StudentHero(onExplore: onExplore!),
        const StudentHeading(
          'Pick up where you left off',
          subtitle: 'Your active courses, ready when you are.',
        ),
      ] else
        StudentHeading(
          mine ? 'Your learning journey' : 'Find your next course',
          subtitle: mine
              ? 'Keep moving forward, one lesson at a time.'
              : 'Explore ideas. Build skills. Find what inspires you.',
        ),
      if (mine && !dashboard)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in ['ACTIVE', 'COMPLETED', 'CANCELLED'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(friendlyStatus(s)),
                    selected: status == s,
                    onSelected: busy
                        ? null
                        : (_) {
                            onStatus(s);
                          },
                  ),
                ),
            ],
          ),
        ),
      if (!mine) ...[
        TextField(
          controller: search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search courses',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              onPressed: busy ? null : onSearch,
              icon: const Icon(Icons.search),
            ),
          ),
          onSubmitted: (_) => onSearch(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          isExpanded: true,
          key: ValueKey(category),
          initialValue: category,
          items: [
            const DropdownMenuItem(value: '', child: Text('All categories')),
            for (final c in categories)
              DropdownMenuItem(value: recordId(c), child: Text('${c['name']}')),
          ],
          onChanged: busy
              ? null
              : (v) {
                  onCategory(v!);
                },
        ),
      ],
      if (!mine && (search.text.isNotEmpty || category.isNotEmpty))
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: busy ? null : onClear,
            icon: const Icon(Icons.filter_alt_off_outlined),
            label: const Text('Clear filters'),
          ),
        ),
      const SizedBox(height: 16),
    ],
  );
}

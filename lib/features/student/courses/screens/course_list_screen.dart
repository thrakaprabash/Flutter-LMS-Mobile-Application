import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/course_list_header.dart';
import '../../learning/services/learning_service.dart';
import '../../learning/widgets/learning_widgets.dart';
import '../../learning/learning_scope.dart';
import '../../../../shared/utils/learning_error.dart';
import '../../widgets/student_ui.dart';
import 'course_details_screen.dart';

class CourseList extends StatefulWidget {
  const CourseList({
    super.key,
    required this.mine,
    this.dashboard = false,
    this.onExplore,
  });
  final bool mine;
  final bool dashboard;
  final VoidCallback? onExplore;
  @override
  State<CourseList> createState() => _CourseListState();
}

class _CourseListState extends State<CourseList> {
  final search = TextEditingController();
  List<Map<String, dynamic>> items = [], categories = [];
  String category = '', status = 'ACTIVE';
  String? error;
  bool busy = false, hasNext = false;
  int page = 0;
  bool lastRequestMore = false;
  void clearFilters() {
    search.clear();
    setState(() {
      category = '';
    });
    load();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    lastRequestMore = more;
    try {
      final service = context.read<LearningService>();
      final next = more ? page + 1 : 1;
      final result = widget.mine
          ? await service.enrollments(next, status)
          : await service.catalogue(
              page: next,
              search: search.text.trim(),
              category: category,
            );
      final cats = !widget.mine && categories.isEmpty
          ? await service.categories()
          : categories;
      if (!mounted) return;
      setState(() {
        items = more ? [...items, ...result.items] : result.items;
        categories = cats;
        page = next;
        hasNext = result.hasNext;
      });
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void open(Map<String, dynamic> course, {bool enrolled = false}) async {
    final child = learningScope(
      context,
      CourseDetails(courseId: recordId(course), enrolled: enrolled),
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => child),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => load(),
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return CourseListHeader(
            mine: widget.mine,
            dashboard: widget.dashboard,
            busy: busy,
            search: search,
            category: category,
            status: status,
            categories: categories,
            onSearch: () => load(),
            onClear: clearFilters,
            onExplore: widget.onExplore,
            onStatus: (value) {
              status = value;
              load();
            },
            onCategory: (value) {
              category = value;
              load();
            },
          );
        }
        if (index == items.length + 1) {
          return Column(
            children: [
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              if (error != null) ...[
                Text(error!),
                TextButton(
                  onPressed: () => load(more: lastRequestMore),
                  child: const Text('Retry'),
                ),
              ],
              if (!busy && error == null && items.isEmpty)
                StudentEmpty(
                  title: widget.mine
                      ? 'Your next chapter starts here'
                      : 'No courses found.',
                  message: widget.mine
                      ? 'Enroll in a course to start learning. Your courses will appear here.'
                      : 'Try another search or choose a different category.',
                ),
              if (hasNext && !busy)
                OutlinedButton(
                  onPressed: () => load(more: true),
                  child: const Text('Load more'),
                ),
            ],
          );
        }
        final item = items[index - 1];
        final course = widget.mine
            ? object(item['courseId'] ?? item['course'])
            : item;
        return CourseCard(
          course: course,
          enrollment: widget.mine ? item : null,
          onRetry: busy ? null : () => load(),
          onOpen: recordId(course).isEmpty
              ? null
              : () => open(
                  course,
                  enrolled:
                      widget.mine &&
                      ['ACTIVE', 'COMPLETED'].contains(item['status']),
                ),
        );
      },
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/learning_error.dart';
import '../../learning/services/learning_service.dart';
import '../../learning/learning_scope.dart';
import '../../learning/screens/lesson_screen.dart';
import '../../widgets/activity_widgets.dart';
import '../../assignments/screens/assignment_screen.dart';
import '../../quizzes/screens/quiz_screen.dart';
import '../../reviews/screens/reviews_screen.dart';
import '../widgets/course_details_view.dart';

class CourseDetails extends StatefulWidget {
  const CourseDetails({
    super.key,
    required this.courseId,
    this.enrolled = false,
  });
  final String courseId;
  final bool enrolled;
  @override
  State<CourseDetails> createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<CourseDetails> {
  Map<String, dynamic>? course, progress;
  List<Map<String, dynamic>> sections = [];
  bool busy = false, enrolled = false;
  String? error, curriculumError, progressError;
  @override
  void initState() {
    super.initState();
    enrolled = widget.enrolled;
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = context.read<LearningService>();
      final c = await s.detail(widget.courseId);
      // Read all enrollment pages so an enrollment on a later page is respected.
      if (!enrolled) {
        for (final status in ['ACTIVE', 'COMPLETED']) {
          var page = 1;
          while (true) {
            final batch = await s.enrollments(page, status);
            if (batch.items.any(
              (e) =>
                  recordId(object(e['courseId'] ?? e['course'])) ==
                      widget.courseId ||
                  e['courseId'] == widget.courseId,
            )) {
              enrolled = true;
            }
            if (!batch.hasNext || enrolled) break;
            page++;
          }
          if (enrolled) break;
        }
      }
      Map<String, dynamic>? p;
      String? progressFailure;
      if (enrolled) {
        try {
          p = await s.progress(widget.courseId);
        } catch (e) {
          p = {};
          progressFailure = learningError(e);
        }
      }
      List<Map<String, dynamic>> sec = [];
      String? denied;
      try {
        sec = await s.sections(widget.courseId);
      } catch (e) {
        denied = learningError(e);
      }
      if (mounted) {
        setState(() {
          course = c;
          progress = p;
          progressError = progressFailure;
          sections = sec;
          curriculumError = denied;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> enroll() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<LearningService>().enroll(widget.courseId);
      enrolled = true;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enrollment successful.')));
        await load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = learningError(e);
          busy = false;
        });
      }
    }
  }

  Map<String, String> get lessonStatuses {
    final result = <String, String>{};
    for (final entry in records(
      progress?['lessons'] ?? progress?['lessonProgress'],
    )) {
      final nested = object(entry['lesson'] ?? entry['lessonId']);
      final id = recordId(nested).isNotEmpty
          ? recordId(nested)
          : (entry['lessonId'] is String
                ? entry['lessonId'].toString()
                : recordId(entry));
      final status = entry['status'] ?? object(entry['progress'])['status'];
      if (id.isNotEmpty && status is String) result[id] = status;
    }
    return result;
  }

  Future<void> continueLearning() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final service = context.read<LearningService>();
      String? first;
      for (final section in sections) {
        final lessons = await service.lessons(recordId(section));
        for (final lesson in lessons) {
          final id = recordId(lesson);
          if (id.isEmpty) continue;
          first ??= id;
          if (lessonStatuses[id] != 'COMPLETED') {
            if (mounted) {
              setState(() => busy = false);
              await openLesson(id);
            }
            return;
          }
        }
      }
      if (mounted && first != null) {
        setState(() => busy = false);
        await openLesson(first);
      } else if (mounted) {
        setState(
          () => error = 'No available lessons yet. Please try again later.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openLesson(String id) async {
    final child = learningScope(
      context,
      LessonScreen(
        lessonId: id,
        enrolled: enrolled,
        initialStatus: lessonStatuses[id],
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => child),
    );
    if (mounted) load();
  }

  void openActivity(String type) {
    final isQuiz = type == 'Quizzes';
    final Widget child = type == 'Reviews'
        ? ReviewsScreen(courseId: widget.courseId, eligible: enrolled)
        : ActivityList(
            title: 'Course ${type.toLowerCase()}',
            path:
                '/api/v1/courses/${widget.courseId}/${isQuiz ? 'quizzes' : 'assignments'}',
            listKey: isQuiz ? 'quizzes' : 'assignments',
            onOpen: (ctx, item) => Navigator.push(
              ctx,
              MaterialPageRoute<void>(
                builder: (_) => learningScope(
                  ctx,
                  isQuiz
                      ? QuizScreen(id: recordId(item))
                      : AssignmentScreen(id: recordId(item)),
                ),
              ),
            ),
          );
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => learningScope(context, child)),
    );
  }

  @override
  Widget build(BuildContext context) => CourseDetailsView(
    course: course,
    progress: progress,
    sections: sections,
    busy: busy,
    enrolled: enrolled,
    error: error,
    curriculumError: curriculumError,
    progressError: progressError,
    lessonStatuses: lessonStatuses,
    load: load,
    enroll: enroll,
    continueLearning: continueLearning,
    openActivity: openActivity,
    openLesson: openLesson,
  );
}

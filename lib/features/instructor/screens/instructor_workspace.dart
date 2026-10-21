import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/models/learning_page.dart';
import '../../../shared/utils/learning_error.dart' show learningError;
import '../../profile/screens/profile_screen.dart';
import '../services/instructor_service.dart';
import 'instructor_editor.dart';
import '../widgets/instructor_widgets.dart';
import '../widgets/instructor_dashboard_view.dart';
import '../widgets/instructor_detail_view.dart';

const api = '/api/v1';
InstructorService instructor(BuildContext context) =>
    InstructorService(context.read<AuthProvider>().service);

class InstructorWorkspace extends StatefulWidget {
  const InstructorWorkspace({
    super.key,
    this.kind = 'home',
    this.id = '',
    this.initial = const {},
    this.readOnly = false,
    this.onDestinationSelected,
  });
  final String kind, id;
  final Record initial;
  final bool readOnly;
  final ValueChanged<int>? onDestinationSelected;
  @override
  State<InstructorWorkspace> createState() => _InstructorWorkspaceState();
}

class _InstructorWorkspaceState extends State<InstructorWorkspace> {
  Record entity = {};
  List<Record> items = [];
  List<Record> recentCourses = [];
  int builderTab = 0;
  bool busy = true, more = false, denied = false;
  int page = 1;
  double? progress;
  String? error;
  String status = '';
  String get kind => widget.kind;
  String get id => widget.id;
  bool get locked =>
      denied || widget.readOnly || entity['status'] == 'ARCHIVED';
  bool get quizLocked => locked || entity['isPublished'] == true;
  InstructorService get service => instructor(context);
  Widget scoped(Widget child) => ChangeNotifierProvider<AuthProvider>.value(
    value: context.read<AuthProvider>(),
    child: child,
  );
  @override
  void initState() {
    super.initState();
    entity = {...widget.initial};
    load();
  }

  String get title => switch (kind) {
    'home' => 'Instructor studio',
    'courses' => 'My courses',
    'course' => '${entity['title'] ?? 'Course builder'}',
    'section' => '${entity['title'] ?? 'Section'}',
    'lesson' => '${entity['title'] ?? 'Lesson'}',
    'quizzes' => 'Quizzes',
    'quiz' => '${entity['title'] ?? 'Quiz'}',
    'assignments' => 'Assignments',
    'assignment' => '${entity['title'] ?? 'Assignment'}',
    'attempts' => 'Student attempts',
    'enrollments' => 'Course enrollments',
    'learners' => 'Learner workspace',
    'learnerCourse' => 'Learner activity',
    'submissions' => 'Student submissions',
    _ => 'Submission review',
  };
  (String, String)? get listing => switch (kind) {
    'courses' => (
      '$api/courses/instructor/me${status.isEmpty ? '' : '?status=$status'}',
      'courses',
    ),
    'learners' => ('$api/courses/instructor/me', 'courses'),
    'course' => ('$api/courses/$id/sections', 'sections'),
    'section' => ('$api/sections/$id/lessons', 'lessons'),
    'quizzes' => ('$api/courses/$id/quizzes/instructor', 'quizzes'),
    'assignments' => ('$api/courses/$id/assignments/instructor', 'assignments'),
    'attempts' => ('$api/quizzes/$id/attempts/instructor', 'attempts'),
    'enrollments' => ('$api/courses/$id/enrollments', 'enrollments'),
    'submissions' => (
      '$api/assignments/$id/submissions${status.isEmpty ? '' : '?status=$status'}',
      'submissions',
    ),
    _ => null,
  };
  Future<void> load({bool next = false}) async {
    final auth = context.read<AuthProvider>();
    if (!auth.authenticated || auth.role != 'INSTRUCTOR') {
      setState(() {
        busy = false;
        denied = true;
      });
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final detail = switch (kind) {
        'home' => ('$api/dashboard/instructor', 'dashboard'),
        'course' => ('$api/courses/instructor/me/$id', 'course'),
        'lesson' => ('$api/lessons/$id', 'lesson'),
        'quiz' => ('$api/quizzes/$id/instructor', 'quiz'),
        _ => null,
      };
      if (!next && detail != null) {
        final result = await service.get(detail.$1, detail.$2);
        if (!mounted) return;
        entity = result;
      }
      if (kind == 'home') {
        try {
          final result = await service.list(
            '$api/courses/instructor/me',
            'courses',
            1,
          );
          if (!mounted) return;
          recentCourses = result.items.take(2).toList();
        } catch (_) {
          // The overview remains usable if only its course preview fails.
          recentCourses = [];
        }
      }
      final path = listing;
      if (path != null) {
        final p = next ? page + 1 : 1;
        final result = await service.list(path.$1, path.$2, p);
        if (!mounted) return;
        items = next ? [...items, ...result.items] : result.items;
        page = p;
        more = result.hasNext;
      }
      denied = false;
    } catch (e) {
      if (mounted) {
        error = learningError(e);
        if (e is DioException && e.response?.statusCode == 403) {
          denied = true;
          items = [];
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(
    String type,
    String record, {
    Record data = const {},
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => scoped(
          InstructorWorkspace(
            kind: type,
            id: record,
            initial: data,
            readOnly: locked,
          ),
        ),
      ),
    );
    if (mounted) await load();
  }

  Future<void> edit(
    String label,
    List<EditorField> fields,
    String path, {
    Record initial = const {},
    String method = 'POST',
    List<Record> categories = const [],
  }) async {
    Record? created;
    final saved = await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => scoped(
          InstructorEditor(
            demo: context.read<AuthProvider>().isDemo,
            title: label,
            fields: fields,
            initial: initial,
            categories: categories,
            onSave: (data) async {
              if (method == 'PATCH') {
                data.removeWhere(
                  (key, value) =>
                      jsonEncode(value) == jsonEncode(initial[key]) ||
                      (value == '' && initial[key] == null),
                );
              } else {
                data.removeWhere((key, value) => value == '');
              }
              if (data.isNotEmpty) {
                final response = await service.save(method, path, data);
                final updated = object(response[kind] ?? response);
                if (method == 'POST') {
                  final key = path == '$api/courses'
                      ? 'course'
                      : path.endsWith('/quizzes')
                      ? 'quiz'
                      : path.endsWith('/assignments')
                      ? 'assignment'
                      : '';
                  if (key.isNotEmpty) {
                    created = object(response[key] ?? response);
                  }
                }
                if (method == 'PATCH' && mounted) {
                  entity = {...entity, ...data, ...updated};
                }
              }
            },
          ),
        ),
      ),
    );
    if (mounted && saved == true) {
      if (created != null && recordId(created!).isNotEmpty) {
        final type = path == '$api/courses'
            ? 'course'
            : path.endsWith('/quizzes')
            ? 'quiz'
            : 'assignment';
        await open(type, recordId(created!), data: created!);
      } else {
        await load();
      }
    }
  }

  Future<void> action(
    String label,
    String path, {
    Record? data,
    bool confirm = false,
  }) async {
    if (confirm &&
        !await confirmActivity(
          context,
          label,
          'This updates the course and its availability. Continue?',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await service.save('PATCH', path, data);
      if (!mounted) return;
      entity = {...entity, ...?data, ...object(result[kind] ?? result)};
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label successful')));
      await load();
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = learningError(e);
        });
      }
    }
  }

  Future<void> upload(String field, String path) async {
    final extensions = switch (field) {
      'thumbnail' => ['jpg', 'jpeg', 'png', 'webp'],
      'video' => ['mp4', 'webm', 'mov'],
      _ => ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
    };
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (!mounted || result.isEmpty) return;
      final file = result.single;
      final limit = field == 'thumbnail'
          ? 5
          : field == 'video'
          ? 100
          : 20;
      final fileSize = await file.length();
      if (fileSize == null ||
          fileSize > limit * 1024 * 1024 ||
          !extensions.contains(file.extension?.toLowerCase())) {
        throw ArgumentError('Choose a supported file up to $limit MB.');
      }
      setState(() {
        busy = true;
        progress = 0;
        error = null;
      });
      if (!mounted) return;
      await service.upload(
        path,
        field,
        MultipartFile.fromStream(
          file.readAsByteStream,
          fileSize,
          filename: file.name,
          contentType: MediaType.parse(
            lookupMimeType(file.name) ?? 'application/octet-stream',
          ),
        ),
        (sent, total) {
          if (mounted) {
            setState(() => progress = total > 0 ? sent / total : null);
          }
        },
      );
      if (mounted) await load();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is ArgumentError ? e.message.toString() : learningError(e);
          busy = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          progress = null;
          busy = false;
        });
      }
    }
  }

  Widget button(
    String label,
    VoidCallback onTap, [
    IconData icon = Icons.add,
  ]) => Padding(
    padding: const EdgeInsets.only(right: 8, bottom: 8),
    child: FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: busy ? null : onTap,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontFamily: 'LmsRoboto')),
    ),
  );
  Future<void> createCourse() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final categories = await service.categories();
      if (!mounted) return;
      if (categories.isEmpty) {
        setState(
          () => error = 'No active categories available. Ask the administrator to add one.',
        );
        return;
      }
      await edit(
        'Create draft course',
        const [EditorField('categoryId', 'Category'), ...courseDetailsFields],
        '$api/courses',
        categories: categories,
      );
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget recordCard(Record item, String type) {
    final onTap = busy ? null : () => open(type, recordId(item), data: item);
    if (type == 'course' || type == 'learnerCourse') {
      return StudioCourseCard(
        item,
        onTap: onTap,
        forLearners: type == 'learnerCourse',
      );
    }
    if (type == 'submission') return StudioLearnerCard(item, onTap: onTap);
    return StudioContentCard(item, type: type, onTap: onTap);
  }

  List<Widget> get controls {
    final base = '$api/courses/$id';
    switch (kind) {
      case 'home':
        return [dashboardOverview(entity)];
      case 'courses':
        return [
          const StudioHeading(
            'Your course library',
            subtitle: 'Your ideas, organized and ready to grow.',
          ),
          button('Create course', createCourse),
          filter(['', 'DRAFT', 'PUBLISHED', 'ARCHIVED']),
        ];
      case 'learners':
        return [
          const StudioHeading(
            'Support every learner',
            subtitle: 'Choose a course to review progress and assessments.',
          ),
        ];
      case 'learnerCourse':
        return [
          StudioHeading(
            '${entity['title'] ?? 'Course activity'}',
            subtitle: 'Results, feedback and the people behind them.',
          ),
          ...managementLinks(),
        ];
      case 'course':
        return [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudioStatus('${entity['status'] ?? 'DRAFT'}'),
                  const SizedBox(height: 12),
                  if ('${entity['shortDescription'] ?? ''}'.isNotEmpty)
                    Text(
                      '${entity['shortDescription']}',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: studioMuted,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (entity['level'] != null)
                        Text(
                          instructorLabel(entity['level']),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: studioInk,
                          ),
                        ),
                      if (entity['language'] != null)
                        Text(
                          '${entity['language']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: studioMuted,
                          ),
                        ),
                    ],
                  ),
                  if (locked)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Archived course · Content is available for reference.',
                        style: TextStyle(fontSize: 12, color: studioMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(['Curriculum', 'Assessments', 'Settings'][i]),
                      selected: builderTab == i,
                      showCheckmark: false,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => builderTab = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (builderTab == 0) ...[
            const StudioHeading(
              'Course curriculum',
              subtitle: 'One clear path from first lesson to finish.',
            ),
            if (!locked)
              button(
                'Add section',
                () => edit('Add section', sectionFields, '$base/sections'),
                Icons.add_rounded,
              ),
          ],
          if (builderTab == 1) ...[
            const StudioHeading(
              'Learning & assessment',
              subtitle: 'Give learners a chance to put ideas into practice.',
            ),
            ...managementLinks(),
          ],
          if (builderTab == 2) ...[
            const StudioHeading('Course settings'),
            ExpansionTile(
              key: PageStorageKey('course-overview-$id'),
              title: const Text('Course overview'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: summary(entity),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!locked) ...[
              StudioAction(
                title: 'Edit course',
                subtitle: 'Title, description and learning goals.',
                icon: Icons.edit_outlined,
                onTap: busy
                    ? null
                    : () => edit(
                        'Edit course',
                        courseDetailsFields,
                        base,
                        initial: entity,
                        method: 'PATCH',
                      ),
              ),
              StudioAction(
                title: 'Upload thumbnail',
                subtitle: 'JPEG, PNG or WebP · Up to 5 MB',
                icon: Icons.image_outlined,
                onTap: busy
                    ? null
                    : () => upload('thumbnail', '$base/thumbnail'),
              ),
              if ('${entity['thumbnailUrl'] ?? ''}'.startsWith('http'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    '${entity['thumbnailUrl']}',
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, st) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 16),
              StudioAction(
                title: 'Archive course',
                subtitle: 'Close new enrollments. Keep existing content and learner records.',
                icon: Icons.archive_outlined,
                color: const Color(0xFFA36348),
                onTap: busy
                    ? null
                    : () => action(
                        'Archive course',
                        '$base/archive',
                        confirm: true,
                      ),
              ),
            ],
          ],
        ];
      case 'section':
        return [
          summary(entity),
          const StudioHeading(
            'Section workspace',
            subtitle: 'Arrange your lessons and control publication.',
          ),
          if (!locked)
            Wrap(
              children: [
                button(
                  'Edit section',
                  () => edit(
                    'Edit section',
                    sectionFields,
                    '$api/sections/$id',
                    initial: entity,
                    method: 'PATCH',
                  ),
                  Icons.edit_outlined,
                ),
                button(
                  entity['isPublished'] == true
                      ? 'Unpublish section'
                      : 'Publish section',
                  () => action(
                    'Update section',
                    '$api/sections/$id',
                    data: {'isPublished': entity['isPublished'] != true},
                    confirm: true,
                  ),
                  Icons.publish,
                ),
                button(
                  'Change order',
                  () => edit(
                    'Section order',
                    const [
                      EditorField(
                        'order',
                        'Position (starts at 1)',
                        kind: 'number',
                      ),
                    ],
                    '$api/sections/$id/reorder',
                    initial: entity,
                    method: 'PATCH',
                  ),
                  Icons.reorder,
                ),
                button(
                  'Add lesson',
                  () => edit(
                    'Add lesson',
                    lessonFields,
                    '$api/sections/$id/lessons',
                    initial: const {'durationMinutes': 5},
                  ),
                ),
              ],
            ),
        ];
      case 'lesson':
        return [
          summary(entity),
          if (!locked)
            Wrap(
              children: [
                button(
                  'Edit lesson',
                  () => edit(
                    'Edit lesson',
                    lessonFields.where((f) => f.key != 'lessonType').toList(),
                    '$api/lessons/$id',
                    initial: entity,
                    method: 'PATCH',
                  ),
                  Icons.edit_outlined,
                ),
                if (entity['lessonType'] == 'VIDEO')
                  button(
                    'Upload video',
                    () => upload('video', '$api/lessons/$id/video'),
                    Icons.video_file_outlined,
                  ),
                if (entity['lessonType'] == 'DOCUMENT')
                  button(
                    'Upload document',
                    () => upload('document', '$api/lessons/$id/document'),
                    Icons.upload_file,
                  ),
                if (entity['isPublished'] != true && lessonReady(entity))
                  button(
                    'Publish lesson',
                    () => action(
                      'Publish lesson',
                      '$api/lessons/$id',
                      data: {'isPublished': true},
                      confirm: true,
                    ),
                    Icons.publish,
                  ),
                if (entity['isPublished'] != true && !lessonReady(entity))
                  const Text(
                    'Add the required text or upload media before publishing.',
                  ),
              ],
            ),
        ];
      case 'quizzes':
        return [
          if (!locked)
            button(
              'Create quiz',
              () => edit(
                'Create quiz',
                quizFields,
                '$base/quizzes',
                initial: const {
                  'passingScore': 60,
                  'timeLimitMinutes': 10,
                  'maxAttempts': 3,
                },
              ),
            ),
        ];
      case 'quiz':
        return [
          summary(entity, excluded: const ['questions']),
          Wrap(
            children: [
              if (!quizLocked) ...[
                button(
                  'Edit settings',
                  () => edit(
                    'Quiz settings',
                    quizFields,
                    '$api/quizzes/$id',
                    initial: entity,
                    method: 'PATCH',
                  ),
                  Icons.settings_outlined,
                ),
                button(
                  'Add question',
                  () => edit(
                    'Add question',
                    questionFields,
                    '$api/quizzes/$id/questions',
                    initial: const {'marks': 1},
                  ),
                ),
                if (records(entity['questions']).isNotEmpty)
                  button(
                    'Publish quiz',
                    () => action(
                      'Publish quiz',
                      '$api/quizzes/$id/publish',
                      confirm: true,
                    ),
                    Icons.publish,
                  ),
              ],
              button(
                'Student attempts',
                () => open('attempts', id),
                Icons.people_outline,
              ),
            ],
          ),
          for (final q in records(entity['questions']))
            StudioQuestionCard(
              q,
              onEdit: quizLocked || busy
                  ? null
                  : () => edit(
                      'Edit question',
                      questionFields,
                      '$api/quiz-questions/${recordId(q)}',
                      initial: q,
                      method: 'PATCH',
                    ),
            ),
        ];
      case 'assignments':
        return [
          if (!locked)
            button(
              'Create assignment',
              () => edit(
                'Create assignment',
                assignmentFields,
                '$base/assignments',
                initial: const {'maximumMarks': 100},
              ),
            ),
        ];
      case 'assignment':
        return [
          summary(entity),
          Wrap(
            children: [
              if (!locked) ...[
                button(
                  'Edit assignment',
                  () => edit(
                    'Edit assignment',
                    assignmentFields,
                    '$api/assignments/$id',
                    initial: entity,
                    method: 'PATCH',
                  ),
                  Icons.edit_outlined,
                ),
                button(
                  'Upload attachment',
                  () => upload('attachment', '$api/assignments/$id/attachment'),
                  Icons.attach_file,
                ),
                if (entity['isPublished'] != true)
                  button(
                    'Publish assignment',
                    () => action(
                      'Publish assignment',
                      '$api/assignments/$id/publish',
                      confirm: true,
                    ),
                    Icons.publish,
                  ),
              ],
              button(
                'Review submissions',
                () => open('submissions', id, data: entity),
                Icons.grading,
              ),
            ],
          ),
        ];
      case 'submissions':
        return [
          filter(['', 'SUBMITTED', 'LATE', 'RESUBMISSION_REQUIRED', 'GRADED']),
        ];
      case 'submission':
        return [
          summary(entity),
          if (!locked)
            button('Grade or request correction', () async {
              final saved = await Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (_) => scoped(
                    InstructorEditor(
                      demo: context.read<AuthProvider>().isDemo,
                      title: 'Review submission',
                      fields: const [
                        EditorField(
                          'status',
                          'Decision',
                          choices: ['GRADED', 'RESUBMISSION_REQUIRED'],
                        ),
                        EditorField(
                          'marksAwarded',
                          'Marks awarded',
                          kind: 'number',
                          required: false,
                        ),
                        EditorField(
                          'feedback',
                          'Feedback',
                          kind: 'long',
                          required: false,
                        ),
                      ],
                      initial: {
                        'marksAwarded': entity['marksAwarded'] ?? 0,
                        'feedback': entity['feedback'] ?? '',
                      },
                      onSave: (data) async {
                        final max =
                            object(
                              entity['assignment'] ?? entity['assignmentId'],
                            )['maximumMarks'] ??
                            entity['maximumMarks'];
                        if (max is! num && data['status'] == 'GRADED') {
                          throw ArgumentError(
                            'Maximum marks are unavailable. Refresh the assignment before grading.',
                          );
                        }
                        InstructorService.validateGrade(
                          data['status'] as String,
                          data['marksAwarded'] as num?,
                          max is num ? max : 0,
                          '${data['feedback'] ?? ''}',
                        );
                        if (data['status'] == 'RESUBMISSION_REQUIRED') {
                          data.remove('marksAwarded');
                        }
                        await service.save(
                          'PATCH',
                          '$api/submissions/$id/grade',
                          data,
                        );
                      },
                    ),
                  ),
                ),
              );
              if (mounted && saved == true) Navigator.pop(context);
            }, Icons.grading),
        ];
      default:
        return [];
    }
  }

  List<Widget> managementLinks() => [
    StudioAction(
      title: 'Quizzes',
      subtitle: 'Create knowledge checks and review quiz results.',
      icon: Icons.quiz_outlined,
      onTap: busy ? null : () => open('quizzes', id),
    ),
    StudioAction(
      title: 'Assignments',
      subtitle: 'Set meaningful tasks and give useful feedback.',
      icon: Icons.assignment_outlined,
      color: const Color(0xFFA9783E),
      onTap: busy ? null : () => open('assignments', id),
    ),
    StudioAction(
      title: 'Enrollments',
      subtitle: 'See who is learning and how they are progressing.',
      icon: Icons.people_outline_rounded,
      color: const Color(0xFF5276A6),
      onTap: busy ? null : () => open('enrollments', id),
    ),
  ];

  Widget filter(List<String> options) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 20),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(switch (option) {
                  '' => 'All',
                  'DRAFT' => 'Drafts',
                  'SUBMITTED' => 'To review',
                  'RESUBMISSION_REQUIRED' => 'Corrections',
                  _ => instructorLabel(option),
                }),
                selected: status == option,
                showCheckmark: false,
                selectedColor: const Color(0xFFDDE9D5),
                side: BorderSide(
                  color: status == option
                      ? const Color(0xFFC5D8B8)
                      : studioLine,
                ),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: status == option
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: studioInk,
                ),
                onSelected: busy
                    ? null
                    : (_) {
                        status = option;
                        load();
                      },
              ),
            ),
        ],
      ),
    ),
  );
  Widget dashboardOverview(Record data) => InstructorDashboardView(
    data: data,
    name: '${context.read<AuthProvider>().user?['firstName'] ?? ''}',
    courses: recentCourses,
    loading: busy,
    onCreate: busy ? null : createCourse,
    onCourses: busy
        ? null
        : () => widget.onDestinationSelected != null
              ? widget.onDestinationSelected!(1)
              : open('courses', ''),
    onLearners: busy
        ? null
        : () => widget.onDestinationSelected != null
              ? widget.onDestinationSelected!(2)
              : open('learners', ''),
    onOpenCourse: (course) => open('course', recordId(course), data: course),
  );

  Widget summary(Record data, {List<String> excluded = const []}) =>
      InstructorDetailView(
        data: data,
        kind: kind,
        excluded: excluded,
        onOpenLink: (value) async {
          final uri = Uri.tryParse(value);
          if (uri != null && ['http', 'https'].contains(uri.scheme)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'INSTRUCTOR') {
      return const Scaffold(
        body: Center(child: Text('Instructor access required.')),
      );
    }
    final type = switch (kind) {
      'courses' => 'course',
      'learners' => 'learnerCourse',
      'course' => 'section',
      'section' => 'lesson',
      'quizzes' => 'quiz',
      'assignments' => 'assignment',
      'submissions' => 'submission',
      _ => 'record',
    };
    final showItems = kind != 'course' || builderTab == 0;
    final root = ['home', 'courses', 'learners'].contains(kind);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.onDestinationSelected == null,
        backgroundColor: const Color(0xFFF6F7F2),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 70,
        titleSpacing: 20,
        title: Text(
          root
              ? kind == 'home'
                    ? 'Teaching studio'
                    : title
              : switch (kind) {
                  'course' => 'Course builder',
                  'section' => 'Section workspace',
                  'lesson' => 'Lesson editor',
                  'quiz' => 'Quiz editor',
                  'assignment' => 'Assignment details',
                  _ => title,
                },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: studioInk,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: busy ? null : () => load(),
            icon: const Icon(Icons.refresh),
          ),
          if (root)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<String>(
                tooltip: 'Account menu',
                onSelected: (value) async {
                  if (value == 'profile') {
                    if (widget.onDestinationSelected != null) {
                      widget.onDestinationSelected!(3);
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => scoped(const ProfileScreen()),
                        ),
                      );
                      if (mounted) await load();
                    }
                  } else {
                    final demo = auth.isDemo;
                    await auth.logout();
                    if (!context.mounted) return;
                    if (demo) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (_) => false,
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('My profile'),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(auth.isDemo ? 'Exit demo' : 'Sign out'),
                  ),
                ],
                child: SizedBox.square(
                  dimension: 36,
                  child: ClipOval(
                    child: Builder(
                      builder: (_) {
                        final name = '${auth.user?['firstName'] ?? ''}'.trim();
                        final fallback = CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE3EBD9),
                          foregroundColor: studioInk,
                          child: Text(
                            name.isEmpty
                                ? 'I'
                                : name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                        final url = auth.user?['profileImageUrl'];
                        return url is String && url.trim().isNotEmpty
                            ? Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stack) => fallback,
                              )
                            : fallback;
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          kind == 'course' && !locked && entity['status'] == 'DRAFT'
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: studioLine)),
              ),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => action(
                          'Publish course',
                          '$api/courses/$id/publish',
                          confirm: true,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: studioInk,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.publish_rounded, size: 20),
                  label: const Text(
                    'Publish course',
                    style: TextStyle(fontFamily: 'LmsRoboto'),
                  ),
                ),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: RefreshIndicator(
            onRefresh: () async {
              if (!busy) await load();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              key: PageStorageKey('instructor-$kind-$id'),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                if (auth.isDemo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EEDF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science_outlined, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DEMO · Uploads simulated · Local changes',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (busy) LinearProgressIndicator(value: progress),
                if (progress != null)
                  Text('Uploading ${(progress! * 100).round()}%'),
                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8ECE6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 22,
                          color: Color(0xFFA36348),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFF80533D),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!root &&
                    ![
                      'quizzes',
                      'assignments',
                      'attempts',
                      'enrollments',
                      'submissions',
                      'learnerCourse',
                    ].contains(kind))
                  StudioHeading(title),
                if (!denied) ...controls,
                if (showItems)
                  for (final item in items)
                    type == 'record'
                        ? StudioLearnerCard(item)
                        : recordCard(
                            kind == 'submissions'
                                ? {
                                    ...item,
                                    'maximumMarks':
                                        widget.initial['maximumMarks'],
                                  }
                                : item,
                            type,
                          ),
                if (showItems &&
                    !busy &&
                    error == null &&
                    listing != null &&
                    items.isEmpty)
                  StudioEmpty(
                    title: switch (kind) {
                      'courses' ||
                      'learners' => 'Your next chapter starts here',
                      'course' => 'Start with a section',
                      'section' => 'Add your first lesson',
                      'submissions' ||
                      'attempts' ||
                      'enrollments' => 'Nothing to review yet',
                      _ => 'Make space for new ideas',
                    },
                    message: switch (kind) {
                      'courses' => 'Create a course and turn your knowledge into a learning experience.',
                      'learners' => 'Your courses and their learner activity will appear here.',
                      'course' =>
                        'Group related lessons into a clear learning path.',
                      'section' =>
                        'Add a text, video or document lesson to get started.',
                      _ =>
                        'New activity will appear here when it is available.',
                    },
                  ),
                if (showItems && more)
                  TextButton(
                    onPressed: busy ? null : () => load(next: true),
                    child: const Text('Load more'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool lessonReady(Record lesson) => switch (lesson['lessonType']) {
  'TEXT' => '${lesson['textContent'] ?? ''}'.trim().isNotEmpty,
  'VIDEO' => '${lesson['videoUrl'] ?? ''}'.isNotEmpty,
  'DOCUMENT' => '${lesson['documentUrl'] ?? ''}'.isNotEmpty,
  _ => false,
};
String humanLabel(String key) =>
    key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');

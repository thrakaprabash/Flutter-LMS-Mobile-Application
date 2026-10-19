import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../shared/providers/auth_provider.dart';
import '../profile/screens/profile_screen.dart';
import 'learning_service.dart';
import 'learning_widgets.dart';
import 'lesson_video_player.dart';
import 'demo_learning_service.dart';
import '../assessments/activity_widgets.dart';
import '../assessments/assignment_screen.dart';
import '../assessments/quiz_screen.dart';
import '../assessments/reviews_screen.dart';
import '../assessments/notifications_screen.dart';

Widget learningScope(BuildContext context, Widget child) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: context.read<AuthProvider>(),
      child: Provider<LearningService>.value(
        value: context.read<LearningService>(),
        child: _LearningAccess(child: child),
      ),
    );

class _LearningAccess extends StatelessWidget {
  const _LearningAccess({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'STUDENT') {
      return const Scaffold(
        body: Center(child: Text('Sign in as a student to continue.')),
      );
    }
    return child;
  }
}

String learningError(Object error) => error is DioException
    ? ApiException.fromDio(error).message
    : error is ApiException
    ? error.message
    : 'Unable to load learning content. Please try again.';

class StudentLearningHome extends StatelessWidget {
  const StudentLearningHome({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Provider<LearningService>(
      key: ObjectKey(auth),
      create: (_) => auth.isDemo
          ? DemoLearningService(auth.service)
          : LearningService(auth.service),
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
      title: Text(['Browse courses', 'My courses', 'Profile'][tab]),
      actions: const [NotificationBell()],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) => setState(() => tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          label: 'Browse courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'My courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    ),
    body: tab == 2
        ? const ProfileScreen()
        : CourseList(key: ValueKey(tab), mine: tab == 1),
  );
}

class CourseList extends StatefulWidget {
  const CourseList({super.key, required this.mine});
  final bool mine;
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.mine ? 'My courses' : 'Find your next course',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (widget.mine)
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: status,
                  items: [
                    for (final s in ['ACTIVE', 'COMPLETED', 'CANCELLED'])
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: busy
                      ? null
                      : (s) {
                          status = s!;
                          load();
                        },
                )
              else ...[
                TextField(
                  controller: search,
                  decoration: InputDecoration(
                    labelText: 'Search courses',
                    suffixIcon: IconButton(
                      onPressed: busy ? null : () => load(),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                  onSubmitted: (_) => load(),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: ValueKey(category),
                  initialValue: category,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All categories'),
                    ),
                    for (final c in categories)
                      DropdownMenuItem(
                        value: recordId(c),
                        child: Text('${c['name']}'),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          category = v!;
                          load();
                        },
                ),
              ],
              if (!widget.mine &&
                  (search.text.isNotEmpty || category.isNotEmpty))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy ? null : clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Clear filters'),
                  ),
                ),
              const SizedBox(height: 16),
            ],
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
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No courses found.'),
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

  @override
  Widget build(BuildContext context) {
    final c = course;
    final p = object(progress?['enrollment'] ?? progress);
    return Scaffold(
      appBar: AppBar(title: const Text('Course details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('Retry'),
            ),
          ],
          if (c != null) ...[
            if (c['thumbnailUrl'] is String)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  c['thumbnailUrl'],
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '${c['title']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${c['description'] ?? ''}'),
            const SizedBox(height: 12),
            Text('Instructor: ${instructorName(c)}'),
            Text('${c['level'] ?? ''} · ${c['language'] ?? ''}'),
            for (final outcome
                in (c['learningOutcomes'] is List
                    ? c['learningOutcomes'] as List
                    : []))
              Text('• $outcome'),
            const SizedBox(height: 16),
            if (enrolled) ...[
              Text(friendlyStatus('${p['status'] ?? 'Enrolled'}')),
              if (progressError != null) Text(progressError!),
              const SizedBox(height: 8),
              CourseProgress(
                value: p['progressPercentage'],
                onRetry: busy ? null : load,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: busy || sections.isEmpty ? null : continueLearning,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue learning'),
              ),
            ] else
              FilledButton.icon(
                onPressed: busy ? null : enroll,
                icon: const Icon(Icons.school_outlined),
                label: const Text('Enroll now'),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (enrolled) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Quizzes'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => learningScope(
                          context,
                          ActivityList(
                            title: 'Course quizzes',
                            path: '/api/v1/courses/${widget.courseId}/quizzes',
                            listKey: 'quizzes',
                            onOpen: (ctx, q) => Navigator.push(
                              ctx,
                              MaterialPageRoute<void>(
                                builder: (_) => learningScope(
                                  ctx,
                                  QuizScreen(id: recordId(q)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Assignments'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => learningScope(
                          context,
                          ActivityList(
                            title: 'Course assignments',
                            path:
                                '/api/v1/courses/${widget.courseId}/assignments',
                            listKey: 'assignments',
                            onOpen: (ctx, a) => Navigator.push(
                              ctx,
                              MaterialPageRoute<void>(
                                builder: (_) => learningScope(
                                  ctx,
                                  AssignmentScreen(id: recordId(a)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Reviews'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => learningScope(
                        context,
                        ReviewsScreen(
                          courseId: widget.courseId,
                          eligible: enrolled,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Curriculum', style: Theme.of(context).textTheme.titleLarge),
            if (curriculumError != null) ...[
              Text(curriculumError!),
              TextButton(
                onPressed: busy ? null : load,
                child: const Text('Retry curriculum'),
              ),
            ],
            if (sections.isEmpty && curriculumError == null && !busy)
              const Text('No available sections.'),
            for (final section in sections)
              _SectionTile(
                section: section,
                onLesson: openLesson,
                statuses: lessonStatuses,
                enrolled: enrolled,
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTile extends StatefulWidget {
  const _SectionTile({
    required this.section,
    required this.onLesson,
    required this.statuses,
    required this.enrolled,
  });
  final Map<String, String> statuses;
  final bool enrolled;
  final Map<String, dynamic> section;
  final void Function(String) onLesson;
  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  Future<List<Map<String, dynamic>>>? future;
  void loadLessons() {
    final request = context.read<LearningService>().lessons(
      recordId(widget.section),
    );
    setState(() {
      future = request;
    });
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text('${widget.section['title']}'),
    subtitle: Text(
      '${widget.section['lessonCount'] ?? widget.section['totalLessons'] ?? ''} lessons',
    ),
    onExpansionChanged: (open) {
      if (open && future == null) {
        loadLessons();
      }
    },
    children: [
      if (future != null)
        FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(learningError(snapshot.error!)),
                  TextButton(
                    onPressed: loadLessons,
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.data!.isEmpty) {
              return const ListTile(title: Text('No available lessons.'));
            }
            return Column(
              children: [
                for (final lesson in snapshot.data!)
                  ListTile(
                    leading: Icon(lessonIcon('${lesson['lessonType']}')),
                    title: Text('${lesson['title']}'),
                    subtitle: Text(
                      '${lesson['lessonType']} · ${!widget.enrolled ? (lesson['isPreview'] == true ? 'Preview' : 'Enrollment required') : friendlyStatus(widget.statuses[recordId(lesson)] ?? 'Progress unavailable')}',
                    ),
                    trailing: Icon(
                      widget.statuses[recordId(lesson)] == 'COMPLETED'
                          ? Icons.check_circle
                          : !widget.enrolled && lesson['isPreview'] != true
                          ? Icons.lock_outline
                          : Icons.chevron_right,
                    ),
                    onTap: !widget.enrolled && lesson['isPreview'] != true
                        ? null
                        : () => widget.onLesson(recordId(lesson)),
                  ),
              ],
            );
          },
        ),
    ],
  );
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.enrolled,
    this.initialStatus,
  });
  final String? initialStatus;
  final String lessonId;
  final bool enrolled;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? lesson;
  VideoPlayerController? video;
  bool busy = false, started = false, completed = false;
  String? error, mediaError;
  @override
  void initState() {
    super.initState();
    completed = widget.initialStatus == 'COMPLETED';
    load();
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  String? mediaUrl(Map<String, dynamic> l) =>
      (l['lessonType'] == 'VIDEO'
              ? l['videoUrl'] ?? object(l['video'])['url']
              : l['documentUrl'] ?? object(l['document'])['url'])
          ?.toString();
  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = context.read<LearningService>();
      final l = await s.lesson(widget.lessonId);
      if (widget.enrolled && !started && !completed) {
        await s.start(widget.lessonId);
        started = true;
      }
      if (!mounted) return;
      setState(() => lesson = l);
      final url = mediaUrl(l);
      if (l['lessonType'] == 'VIDEO' && url != null && video == null) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));
        video = controller;
        controller.addListener(() {
          if (mounted && controller.value.hasError && mediaError == null) {
            setState(
              () => mediaError =
                  'Video playback interrupted. Please retry the video.',
            );
          }
        });
        try {
          await controller.initialize();
        } catch (_) {
          mediaError =
              'Unable to play this video. Check your connection and retry.';
        }
      }
    } catch (e) {
      error = learningError(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> complete() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<LearningService>().complete(widget.lessonId);
      if (mounted) {
        setState(() => completed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson completed. Return to the course to see updated progress.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!['http', 'https'].contains(uri.scheme) ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw const FormatException();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => mediaError = 'Unable to open this document. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    final demo = context.watch<AuthProvider>().isDemo;
    return Scaffold(
      appBar: AppBar(title: Text('${l?['title'] ?? 'Lesson'}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('Retry'),
            ),
          ],
          if (l != null) ...[
            if (demo && l['lessonType'] != 'TEXT')
              const Text(
                'Demo media  -  Public sample  -  Internet connection required',
              ),
            Text(
              '${l['lessonType']}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            if (l['lessonType'] == 'TEXT')
              SelectableText('${l['textContent'] ?? 'No text available.'}'),
            if (l['lessonType'] == 'VIDEO' &&
                video?.value.isInitialized == true) ...[
              LessonVideoPlayer(
                controller: video!,
                title: '${l['title'] ?? 'Lesson video'}',
                routeScope: (child) => learningScope(context, child),
              ),
            ],
            if (mediaError != null) ...[
              Text(mediaError!),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        final old = video;
                        video = null;
                        mediaError = null;
                        await old?.dispose();
                        if (mounted) load();
                      },
                child: const Text('Retry media'),
              ),
            ],
            if (l['lessonType'] != 'TEXT' && mediaUrl(l) == null)
              Text(
                demo
                    ? 'Demo media lesson. Sign in to access uploaded course videos and documents.'
                    : 'The lesson media is unavailable.',
              ),
            if (l['lessonType'] == 'DOCUMENT' && mediaUrl(l) != null)
              FilledButton.icon(
                onPressed: () => openDocument(mediaUrl(l)!),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open document'),
              ),
            const SizedBox(height: 24),
            if (widget.enrolled)
              FilledButton(
                onPressed: busy || completed ? null : complete,
                child: Text(completed ? 'Lesson completed' : 'Mark complete'),
              )
            else
              const Text('Preview lesson. Enroll to record your progress.'),
          ],
        ],
      ),
    );
  }
}

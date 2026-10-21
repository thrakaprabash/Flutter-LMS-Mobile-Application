import 'package:flutter/material.dart';

import '../../widgets/student_ui.dart';

import '../../learning/services/learning_service.dart';
import '../../../../shared/utils/learning_error.dart';
import '../../widgets/activity_widgets.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.id});
  final String id;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic> quiz = {}, attempt = {};
  List<Map<String, dynamic>> questions = [], history = [];
  final answers = <String, Set<String>>{};
  bool busy = false, submitted = false;
  String? error;
  @override
  void initState() {
    super.initState();
    run(load);
  }

  Future<void> load() async {
    final s = activityService(context);
    final data = await s.get('/api/v1/quizzes/${widget.id}');
    quiz = object(data['quiz'] ?? data);
    questions = records(data['questions'] ?? quiz['questions']);
    history = [];
    var page = 1;
    while (true) {
      final batch = await s.list(
        '/api/v1/quizzes/${widget.id}/attempts/me',
        'attempts',
        page++,
      );
      history.addAll(batch.items);
      if (!batch.hasNext) break;
    }
    final active = history.where((a) => a['status'] == 'IN_PROGRESS');
    if (active.isNotEmpty && attempt.isEmpty) attempt = active.first;
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = learningError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> start() => run(() async {
    final data = await activityService(context)
        .mutate('POST', '/api/v1/quizzes/${widget.id}/start');
    attempt = object(data['attempt'] ?? data);
    if (data['questions'] is List) questions = records(data['questions']);
    submitted = false;
    answers.clear();
  });
  Future<void> submit() async {
    if (!await confirmActivity(
      context,
      'Submit quiz?',
      'Your selected answers will be submitted for grading.',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      final data = await activityService(context).mutate(
        'POST',
        '/api/v1/quiz-attempts/${recordId(attempt)}/submit',
        data: {
          'answers': [
            for (final q in questions)
              {
                'questionId': recordId(q),
                'selectedOptionIds': (answers[recordId(q)] ?? {}).toList(),
              },
          ],
        },
      );
      attempt = {
        ...attempt,
        ...object(data['attempt'] ?? data['result'] ?? data),
      };
      history.removeWhere((a) => recordId(a) == recordId(attempt));
      submitted = true;
    });
  }

  Widget result(Map<String, dynamic> a) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attempt ${a['attemptNumber'] ?? '—'}'),
          ActivityStatus('${a['status'] ?? 'Unavailable'}'),
          Text('Score: ${a['score'] ?? '—'} / ${a['totalMarks'] ?? '—'}'),
          Text('Percentage: ${a['percentage'] ?? '—'}%'),
          Text(
            a['passed'] == true
                ? 'Passed'
                : a['passed'] == false
                ? 'Failed'
                : 'Result pending',
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final active =
        attempt.isNotEmpty && !submitted && attempt['status'] == 'IN_PROGRESS';
    return Scaffold(
      appBar: AppBar(title: Text('${quiz['title'] ?? 'Quiz'}')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (busy) const LinearProgressIndicator(),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: busy ? null : () => run(load),
              child: const Text('Refresh quiz'),
            ),
          ],
          StudentHeading(
            active ? 'Show what you know' : 'Ready to test your knowledge?',
            subtitle: '${quiz['description'] ?? ''}',
          ),
          StudentPanel(
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                Text('Time limit: ${quiz['timeLimitMinutes'] ?? '—'} minutes'),
                Text('Maximum attempts: ${quiz['maxAttempts'] ?? '—'}'),
                Text(
                  'Passing score: ${quiz['passingScore'] ?? '—'}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: studentInk,
                  ),
                ),
              ],
            ),
          ),
          if (attempt['expiresAt'] != null)
            Text('Attempt deadline: ${attempt['expiresAt']}'),
          if (active) ...[
            for (final q in questions)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${q['questionText'] ?? ''}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      for (final option in records(q['options']))
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${option['text'] ?? ''}'),
                          value:
                              answers[recordId(q)]?.contains(
                                '${option['id']}',
                              ) ??
                              false,
                          onChanged: busy
                              ? null
                              : (checked) => setState(() {
                                  final selected = answers.putIfAbsent(
                                    recordId(q),
                                    () => <String>{},
                                  );
                                  if (q['questionType'] != 'MULTIPLE_CHOICE') {
                                    selected.clear();
                                  }
                                  if (checked == true) {
                                    selected.add('${option['id']}');
                                  } else {
                                    selected.remove('${option['id']}');
                                  }
                                }),
                        ),
                    ],
                  ),
                ),
              ),
            FilledButton(
              onPressed: busy ? null : submit,
              child: const Text('Submit quiz'),
            ),
          ] else if (submitted) ...[
            result(attempt),
            TextButton(
              onPressed: busy ? null : start,
              child: const Text('Start another attempt'),
            ),
          ] else if (quiz.isNotEmpty)
            FilledButton(
              onPressed: busy ? null : start,
              child: const Text('Start quiz'),
            ),
          const SizedBox(height: 24),
          Text(
            'Attempt history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final a in history) result(a),
        ],
      ),
    );
  }
}

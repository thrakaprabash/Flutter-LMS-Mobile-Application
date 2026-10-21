import 'package:flutter/material.dart';

import '../../../shared/models/learning_page.dart';
import '../../../shared/utils/learning_error.dart' show learningError;
import '../widgets/instructor_widgets.dart';

typedef Record = Map<String, dynamic>;

class EditorField {
  const EditorField(
    this.key,
    this.label, {
    this.kind = 'text',
    this.choices = const [],
    this.required = true,
    this.minLength = 0,
    this.maxLength,
    this.maxItems,
  });
  final String key, label, kind;
  final List<String> choices;
  final bool required;
  final int minLength;
  final int? maxLength, maxItems;
}

const courseDetailsFields = [
  EditorField('title', 'Title', minLength: 3, maxLength: 150),
  EditorField(
    'shortDescription',
    'Short description',
    minLength: 10,
    maxLength: 250,
  ),
  EditorField(
    'description',
    'Description',
    kind: 'long',
    minLength: 20,
    maxLength: 5000,
  ),
  EditorField(
    'level',
    'Level',
    choices: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ALL_LEVELS'],
  ),
  EditorField('language', 'Language', minLength: 2, maxLength: 50),
  EditorField(
    'requirements',
    'Requirements (one per line)',
    kind: 'lines',
    required: false,
    minLength: 2,
    maxLength: 200,
    maxItems: 20,
  ),
  EditorField(
    'learningOutcomes',
    'Learning outcomes (one per line)',
    kind: 'lines',
    required: false,
    minLength: 2,
    maxLength: 200,
    maxItems: 20,
  ),
  EditorField(
    'targetAudience',
    'Target audience (one per line)',
    kind: 'lines',
    required: false,
    minLength: 2,
    maxLength: 200,
    maxItems: 20,
  ),
];

String? editorLengthError(EditorField field, String value) {
  final text = value.trim();
  if (text.isEmpty) return field.required ? 'Required' : null;
  final values = field.kind == 'lines'
      ? text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
      : [text];
  if (field.maxItems != null && values.length > field.maxItems!) {
    return 'Use at most ${field.maxItems} items.';
  }
  for (final item in values) {
    if (item.length < field.minLength) {
      return '${field.kind == 'lines' ? 'Each item needs' : 'Enter'} at least ${field.minLength} characters.';
    }
    if (field.maxLength != null && item.length > field.maxLength!) {
      return '${field.kind == 'lines' ? 'Each item allows' : 'Use'} at most ${field.maxLength} characters.';
    }
  }
  return null;
}

const titleField = EditorField('title', 'Title');
const descriptionField = EditorField(
  'description',
  'Description',
  required: false,
  kind: 'long',
);
const sectionFields = [titleField, descriptionField];
const lessonFields = [
  titleField,
  descriptionField,
  EditorField(
    'lessonType',
    'Lesson type',
    choices: ['TEXT', 'VIDEO', 'DOCUMENT'],
  ),
  EditorField('textContent', 'Text content', kind: 'long', required: false),
  EditorField('durationMinutes', 'Duration in minutes', kind: 'number'),
  EditorField('isPreview', 'Allow preview', kind: 'bool'),
];
const quizFields = [
  titleField,
  descriptionField,
  EditorField('passingScore', 'Passing percentage', kind: 'number'),
  EditorField('timeLimitMinutes', 'Time limit in minutes', kind: 'number'),
  EditorField('maxAttempts', 'Maximum attempts', kind: 'number'),
];
const assignmentFields = [
  titleField,
  descriptionField,
  EditorField('instructions', 'Instructions', kind: 'long'),
  EditorField('dueDate', 'Due date and time', kind: 'date'),
  EditorField('maximumMarks', 'Maximum marks', kind: 'number'),
];
const questionFields = [
  EditorField('questionText', 'Question', kind: 'long'),
  EditorField(
    'questionType',
    'Question type',
    choices: ['SINGLE_CHOICE', 'MULTIPLE_CHOICE', 'TRUE_FALSE'],
  ),
  EditorField('options', 'Options (one per line: A: Answer)', kind: 'options'),
  EditorField(
    'correctOptionIds',
    'Correct option IDs (one per line)',
    kind: 'lines',
  ),
  EditorField('marks', 'Marks', kind: 'number'),
];

class InstructorEditor extends StatefulWidget {
  const InstructorEditor({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.initial = const {},
    this.categories = const [],
    this.demo = false,
  });
  final String title;
  final List<EditorField> fields;
  final Record initial;
  final List<Record> categories;
  final bool demo;
  final Future<void> Function(Record) onSave;
  @override
  State<InstructorEditor> createState() => _InstructorEditorState();
}

class _InstructorEditorState extends State<InstructorEditor> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final values = <String, dynamic>{};
  bool busy = false;
  String? error;
  final answers = <(String, TextEditingController)>[];
  final correctAnswers = <String>{};
  bool get hasAnswers => widget.fields.any((f) => f.kind == 'options');
  String nextAnswerId() {
    var index = 0;
    while (true) {
      final id = index < 26
          ? String.fromCharCode(65 + index)
          : 'answer-${index + 1}';
      if (!answers.any((answer) => answer.$1 == id)) return id;
      index++;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final raw = widget.initial[f.key];
      if (f.kind == 'bool') {
        values[f.key] = raw == true;
      } else if (f.choices.isNotEmpty || f.key == 'categoryId') {
        values[f.key] = raw ?? (f.choices.isNotEmpty ? f.choices.first : null);
      } else {
        final text = f.kind == 'options'
            ? records(raw).map((o) => '${o['id']}: ${o['text']}').join('\n')
            : raw is List
            ? raw.join('\n')
            : raw?.toString() ?? '';
        controllers[f.key] = TextEditingController(text: text);
      }
    }
    if (hasAnswers) {
      for (final option in records(widget.initial['options'])) {
        final rawId = '${option['id'] ?? ''}';
        final id = rawId.isEmpty || answers.any((a) => a.$1 == rawId)
            ? nextAnswerId()
            : rawId;
        answers.add((
          id,
          TextEditingController(text: '${option['text'] ?? ''}'),
        ));
      }
      while (answers.length < 2) {
        answers.add((nextAnswerId(), TextEditingController()));
      }
      correctAnswers.addAll(
        (widget.initial['correctOptionIds'] as List? ?? [])
            .map((id) => '$id')
            .where((id) => answers.any((a) => a.$1 == id)),
      );
    }
  }

  @override
  void dispose() {
    for (final answer in answers) {
      answer.$2.dispose();
    }
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(String key) async {
    final initial =
        DateTime.tryParse(controllers[key]!.text)?.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    controllers[key]!.text = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toIso8601String().substring(0, 16).replaceAll('T', ' ');
  }

  Future<void> save() async {
    if (hasAnswers) {
      controllers['options']!.text = answers
          .map((a) => '${a.$1}: ${a.$2.text.trim()}')
          .join('\n');
      controllers['correctOptionIds']!.text = correctAnswers.join('\n');
    }
    final invalid = form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        alignment: .15,
        duration: const Duration(milliseconds: 200),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = <String, dynamic>{};
      for (final f in widget.fields) {
        if (values.containsKey(f.key)) {
          data[f.key] = values[f.key];
          continue;
        }
        final text = controllers[f.key]!.text.trim();
        if (text.isEmpty && !f.required && f.kind == 'number') continue;
        data[f.key] = switch (f.kind) {
          'number' => num.parse(text),
          'date' => DateTime.parse(text).toUtc().toIso8601String(),
          'lines' =>
            text
                .split('\n')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
          'options' => text.split('\n').map((line) {
            final split = line.indexOf(':');
            if (split < 1 || line.substring(split + 1).trim().isEmpty) {
              throw ArgumentError(
                'Each option needs an ID and answer, for example A: Dart.',
              );
            }
            return {
              'id': line.substring(0, split).trim(),
              'text': line.substring(split + 1).trim(),
            };
          }).toList(),
          _ => text,
        };
      }
      if (data.containsKey('questionType')) {
        final options = records(data['options']);
        final ids = options.map((o) => o['id']).toSet();
        final correct = data['correctOptionIds'] as List;
        if (correct.isEmpty) {
          throw ArgumentError('Choose the correct answer before saving.');
        }
        if (options.length < 2 ||
            ids.length != options.length ||
            correct.isEmpty ||
            correct.toSet().length != correct.length ||
            !correct.every(ids.contains) ||
            (data['questionType'] != 'MULTIPLE_CHOICE' &&
                correct.length != 1) ||
            (data['questionType'] == 'TRUE_FALSE' && options.length != 2)) {
          throw ArgumentError(
            'Use unique options and valid correct IDs. Single choice and true/false require one correct answer.',
          );
        }
      }
      await widget.onSave(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ArgumentError
              ? e.message.toString()
              : learningError(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String choiceLabel(String value) => switch (value) {
    'RESUBMISSION_REQUIRED' => 'Request correction',
    'GRADED' => 'Grade submission',
    'TRUE_FALSE' => 'True / false',
    _ => instructorLabel(value),
  };

  void choose(EditorField field, String? value) {
    setState(() {
      values[field.key] = value;
      if (field.key == 'questionType') {
        if (value == 'TRUE_FALSE') {
          for (final answer in answers.skip(2)) {
            answer.$2.dispose();
          }
          if (answers.length > 2) answers.removeRange(2, answers.length);
          answers[0].$2.text = 'True';
          answers[1].$2.text = 'False';
          correctAnswers.removeWhere((id) => !answers.any((a) => a.$1 == id));
        }
        if (value != 'MULTIPLE_CHOICE' && correctAnswers.length > 1) {
          final first = correctAnswers.first;
          correctAnswers
            ..clear()
            ..add(first);
        }
      }
    });
  }

  Widget answerInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        values['questionType'] == 'MULTIPLE_CHOICE'
            ? 'Select every correct answer.'
            : 'Select the one correct answer.',
        style: const TextStyle(fontSize: 12, color: studioMuted),
      ),
      const SizedBox(height: 14),
      for (var index = 0; index < answers.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 12, 8, 12),
            decoration: BoxDecoration(
              color: correctAnswers.contains(answers[index].$1)
                  ? const Color(0xFFF0F5EA)
                  : const Color(0xFFFAFBF8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: correctAnswers.contains(answers[index].$1)
                    ? const Color(0xFFB9D0AA)
                    : studioLine,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Mark answer ${index + 1} correct',
                  child: Checkbox(
                    value: correctAnswers.contains(answers[index].$1),
                    shape: values['questionType'] == 'MULTIPLE_CHOICE'
                        ? null
                        : const CircleBorder(),
                    onChanged: busy
                        ? null
                        : (selected) => setState(() {
                            if (selected == true) {
                              if (values['questionType'] != 'MULTIPLE_CHOICE') {
                                correctAnswers.clear();
                              }
                              correctAnswers.add(answers[index].$1);
                            } else {
                              correctAnswers.remove(answers[index].$1);
                            }
                          }),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('answer-${answers[index].$1}'),
                    controller: answers[index].$2,
                    enabled: !busy,
                    readOnly: values['questionType'] == 'TRUE_FALSE',
                    decoration: InputDecoration(
                      labelText: 'Answer ${index + 1}',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Add an answer.' : null,
                  ),
                ),
                if (values['questionType'] != 'TRUE_FALSE' &&
                    answers.length > 2)
                  IconButton(
                    tooltip: 'Remove answer ${index + 1}',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            final removed = answers.removeAt(index);
                            correctAnswers.remove(removed.$1);
                            removed.$2.dispose();
                          }),
                  ),
              ],
            ),
          ),
        ),
      if (values['questionType'] != 'TRUE_FALSE')
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: busy
                ? null
                : () => setState(
                    () =>
                        answers.add((nextAnswerId(), TextEditingController())),
                  ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add answer'),
          ),
        ),
    ],
  );

  String? validate(EditorField field, String? value) {
    final v = value?.trim() ?? '';
    final lengthError = editorLengthError(field, v);
    if (lengthError != null) return lengthError;
    if (field.kind == 'number' &&
        v.isNotEmpty &&
        (num.tryParse(v) == null ||
            !num.parse(v).isFinite ||
            num.parse(v) < 0)) {
      return 'Enter a valid positive number.';
    }
    if (field.kind == 'date' && DateTime.tryParse(v) == null) {
      return 'Choose a due date and time.';
    }
    return null;
  }

  Widget input(EditorField field) {
    if (field.kind == 'options') return answerInput();
    if (field.kind == 'bool') {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label, style: const TextStyle(fontSize: 14)),
        subtitle: const Text(
          'Let learners explore this lesson before enrollment.',
          style: TextStyle(fontSize: 12),
        ),
        value: values[field.key] == true,
        onChanged: busy
            ? null
            : (value) => setState(() => values[field.key] = value),
      );
    }
    final decoration = InputDecoration(
      labelText: '${field.label}${field.required ? ' *' : ''}',
      alignLabelWithHint: true,
      helperMaxLines: 3,
      helperText: field.minLength > 0
          ? field.kind == 'lines'
                ? '${field.minLength}-${field.maxLength} characters per item; up to ${field.maxItems} items.'
                : '${field.minLength}-${field.maxLength} characters.'
          : null,
      suffixIcon: field.kind == 'date'
          ? const Icon(Icons.calendar_today_outlined, size: 18)
          : null,
      filled: true,
      fillColor: const Color(0xFFFAFBF8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: studioLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: studioLine),
      ),
    );
    if (field.choices.isNotEmpty || field.key == 'categoryId') {
      return DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: values[field.key] as String?,
        decoration: decoration,
        items: field.key == 'categoryId'
            ? widget.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: recordId(c),
                      child: Text(
                        '${c['name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList()
            : field.choices
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        choiceLabel(value),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
        onChanged: busy ? null : (value) => choose(field, value),
        validator: (value) => field.required && value == null
            ? 'Choose ${field.label.toLowerCase()}.'
            : null,
      );
    }
    return TextFormField(
      key: ValueKey(field.key),
      controller: controllers[field.key],
      enabled: !busy,
      readOnly: field.kind == 'date',
      onTap: field.kind == 'date' ? () => pickDate(field.key) : null,
      maxLines: ['long', 'lines'].contains(field.kind) ? 4 : 1,
      keyboardType: field.kind == 'number'
          ? TextInputType.number
          : ['long', 'lines'].contains(field.kind)
          ? TextInputType.multiline
          : TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      decoration: decoration,
      validator: (value) => validate(field, value),
    );
  }

  String group(EditorField field) => switch (field.key) {
    'requirements' ||
    'learningOutcomes' ||
    'targetAudience' => 'The learning journey',
    'options' || 'correctOptionIds' => 'Answer choices',
    'level' ||
    'language' ||
    'durationMinutes' ||
    'isPreview' ||
    'dueDate' ||
    'maximumMarks' ||
    'passingScore' ||
    'timeLimitMinutes' ||
    'maxAttempts' ||
    'marks' => 'Details & preferences',
    'feedback' || 'marksAwarded' || 'status' => 'Review & feedback',
    _ => 'The essentials',
  };

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<EditorField>>{};
    for (final field in widget.fields) {
      if (hasAnswers && field.key == 'correctOptionIds') continue;
      if (field.key == 'textContent' &&
          (values['lessonType'] ?? widget.initial['lessonType']) != 'TEXT') {
        continue;
      }
      groups.putIfAbsent(group(field), () => []).add(field);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: studioInk,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: studioLine)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA36348),
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: busy ? null : save,
                style: FilledButton.styleFrom(
                  backgroundColor: studioInk,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Save',
                  style: TextStyle(fontFamily: 'LmsRoboto'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.demo)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF1E3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Demo workspace · Changes stay in this session.',
                        style: TextStyle(fontSize: 12, color: studioMuted),
                      ),
                    ),
                  const Text(
                    'Make it clear. Make it yours.',
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: studioInk,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'A few thoughtful details help learners know what to expect. Fields marked * are required.',
                    style: TextStyle(
                      fontSize: 13,
                      color: studioMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final entry in groups.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: studioLine),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: studioMuted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (
                              var index = 0;
                              index < entry.value.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(height: 20),
                              input(entry.value[index]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

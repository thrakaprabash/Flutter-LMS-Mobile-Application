import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/learning_page.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../providers/admin_provider.dart';
import '../services/admin_service.dart';
import '../widgets/admin_ui.dart';

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({
    super.key,
    required this.feature,
    this.courseId,
    this.selecting = false,
  });
  final String feature;
  final String? courseId;
  final bool selecting;
  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  late final AdminProvider state;
  final search = TextEditingController();
  final selectedLabels = <String, String>{};
  final Map<String, Map<String, dynamic>> hiddenReviews = {};
  String get screenTitle => switch (widget.feature) {
    'users' => 'People & access',
    'courses' => 'Course catalog',
    'categories' => 'Categories',
    'enrollments' => 'Enrollments',
    'reviews' => 'Course reviews',
    _ => 'Platform',
  };
  String get subtitle => switch (widget.feature) {
    'users' => 'Your learning community, all in one place.',
    'courses' => 'A clear view of every course on your platform.',
    'categories' => 'Make great courses easier to discover.',
    'enrollments' => 'Follow participation across your learning community.',
    'reviews' => 'Give helpful feedback the visibility it deserves.',
    _ => '',
  };
  String get heading => switch (widget.feature) {
    'users' => 'Your learning community',
    'courses' => 'Explore your course catalog',
    'categories' => 'Organize discovery',
    'enrollments' => 'Learner participation',
    'reviews' => 'Learner feedback',
    _ => screenTitle,
  };
  @override
  void initState() {
    super.initState();
    state = AdminProvider(
      AdminService(context.read<AuthProvider>()),
      widget.feature,
      courseId: widget.courseId,
    );
    if (widget.selecting && widget.feature == 'users') {
      state.filters['role'] = 'INSTRUCTOR';
    }
    state.load();
  }

  @override
  void dispose() {
    state.dispose();
    search.dispose();
    super.dispose();
  }

  String title(Map<String, dynamic> row) =>
      (row['title'] ??
              row['name'] ??
              [row['firstName'], row['lastName']].whereType<String>().join(' '))
          .toString();

  Future<void> action(
    String label,
    String path, {
    Map<String, dynamic>? data,
    String method = 'PATCH',
  }) async {
    if (!await confirmActivity(context, label, switch (label) {
      'Archive course' => 'Archive this course? It will no longer be available for new enrollments.',
      'Suspend user' => 'Suspend this account? The user will lose access until the account is reactivated.',
      'Reactivate user' => 'Restore access for this account?',
      _ => 'Update the availability of this category?',
    })) {
      return;
    }
    if (!mounted) return;
    final ok = await state.mutate(method, path, data: data);
    if (mounted && ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label completed.')));
    }
  }

  Future<void> category([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name']?.toString());
    final description = TextEditingController(
      text: row?['description']?.toString(),
    );
    final form = GlobalKey<FormState>();
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row == null ? 'Create category' : 'Edit category'),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Design & creativity',
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Enter at least 2 characters.'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: description,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Help learners understand this subject',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, {
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Dialog removal animations can still reference its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose();
    description.dispose();
    if (payload == null || !mounted) return;
    await state.mutate(
      row == null ? 'POST' : 'PATCH',
      row == null ? 'categories' : 'categories/${recordId(row)}',
      data: payload,
    );
  }

  Widget dropdown(String key, String label, List<String> values) =>
      DropdownButtonFormField<String>(
        key: ValueKey('$key:${state.filters[key]}'),
        initialValue: state.filters[key] ?? '',
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: ['', ...values]
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v.isEmpty ? 'All' : adminLabel(v)),
              ),
            )
            .toList(),
        onChanged: state.saving ? null : (v) => state.filter(key, v ?? ''),
      );

  Widget recordFilter(String feature, String key, String label) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.filter_alt_outlined),
          label: Text(selectedLabels[key] ?? label),
          onPressed: state.saving
              ? null
              : () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminListScreen(feature: feature, selecting: true),
                    ),
                  );
                  if (result == null || !mounted) return;
                  selectedLabels[key] = title(result);
                  await state.filter(key, recordId(result));
                },
        ),
      ),
      if (state.filters.containsKey(key))
        IconButton(
          tooltip: 'Clear $label',
          icon: const Icon(Icons.close),
          onPressed: state.saving
              ? null
              : () {
                  selectedLabels.remove(key);
                  state.filter(key, '');
                },
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.authenticated || auth.role != 'ADMIN') {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final rows = [
          ...state.items,
          ...hiddenReviews.values.where(
            (r) => !state.items.any((item) => recordId(item) == recordId(r)),
          ),
        ];
        return Scaffold(
          backgroundColor: adminCanvas,
          appBar: AppBar(
            backgroundColor: adminCanvas,
            surfaceTintColor: Colors.transparent,
            title: Text(
              widget.selecting
                  ? 'Select ${widget.feature == 'users' ? 'instructor' : widget.feature}'
                  : screenTitle,
              style: const TextStyle(
                color: adminInk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.loading || state.saving
                    ? null
                    : () => state.load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          floatingActionButton:
              widget.feature == 'categories' && !widget.selecting
              ? FloatingActionButton.extended(
                  backgroundColor: adminInk,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  onPressed: state.saving ? null : category,
                  icon: const Icon(Icons.add),
                  label: const Text('Category'),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () => state.load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                AdminHeading(
                  widget.selecting
                      ? 'Find the right ${widget.feature == 'users'
                            ? 'instructor'
                            : widget.feature == 'categories'
                            ? 'category'
                            : 'course'}'
                      : heading,
                  subtitle: subtitle,
                ),
                if (['users', 'courses'].contains(widget.feature)) ...[
                  TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText:
                          'Search ${widget.feature == 'users' ? 'by name or email' : 'courses'}',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: adminMuted,
                        size: 21,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        onPressed: () =>
                            state.filter('search', search.text.trim()),
                      ),
                    ),
                    onSubmitted: (v) => state.filter('search', v.trim()),
                  ),
                  const SizedBox(height: 12),
                ],
                if ([
                  'users',
                  'courses',
                  'enrollments',
                ].contains(widget.feature))
                  AdminPanel(
                    padding: 0,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          18,
                        ),
                        leading: const Icon(
                          Icons.tune_rounded,
                          color: adminInk,
                          size: 20,
                        ),
                        title: Text(
                          state.filters.isEmpty
                              ? 'Filter & refine'
                              : 'Filters applied (${state.filters.length})',
                          style: const TextStyle(
                            color: adminInk,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          if (widget.feature == 'users') ...[
                            if (!widget.selecting)
                              dropdown('role', 'Role', [
                                'STUDENT',
                                'INSTRUCTOR',
                                'ADMIN',
                              ]),
                            const SizedBox(height: 12),
                            dropdown('status', 'Status', [
                              'ACTIVE',
                              'SUSPENDED',
                              'INACTIVE',
                            ]),
                          ],
                          if (widget.feature == 'courses') ...[
                            dropdown('status', 'Status', [
                              'DRAFT',
                              'PUBLISHED',
                              'ARCHIVED',
                            ]),
                            const SizedBox(height: 12),
                            recordFilter(
                              'users',
                              'instructorId',
                              'Choose instructor',
                            ),
                            const SizedBox(height: 12),
                            recordFilter(
                              'categories',
                              'categoryId',
                              'Choose category',
                            ),
                          ],
                          if (widget.feature == 'enrollments')
                            recordFilter(
                              'courses',
                              'courseId',
                              'Choose course',
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.selecting
                            ? 'Available records'
                            : 'All ${widget.feature}',
                        style: const TextStyle(
                          color: adminInk,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!state.loading)
                      Text(
                        '${rows.length} loaded',
                        style: const TextStyle(color: adminMuted, fontSize: 11),
                      ),
                  ],
                ),
                if (widget.feature == 'reviews')
                  const AdminNotice(
                    'Only public reviews are listed. You can restore reviews hidden here until you leave this screen.',
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: state.loading || state.saving ? 16 : 0,
                  child: state.loading || state.saving
                      ? const LinearProgressIndicator()
                      : null,
                ),
                if (state.error != null)
                  AdminNotice(
                    state.error!,
                    error: true,
                    action: TextButton(
                      onPressed: state.loading ? null : () => state.load(),
                      child: const Text('Retry'),
                    ),
                  ),
                if (!state.loading && state.error == null && rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: AdminPanel(
                      child: Column(
                        children: [
                          Icon(
                            adminIcon(widget.feature),
                            color: adminMuted,
                            size: 36,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nothing here yet',
                            style: TextStyle(
                              color: adminInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.filters.isEmpty
                                ? 'Your ${widget.feature} will appear here.'
                                : 'Try another search or adjust your filters.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: adminMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...rows.map(card),
                if (state.hasNext)
                  OutlinedButton(
                    onPressed: state.loading || state.saving
                        ? null
                        : () => state.load(more: true),
                    child: const Text('Load more'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget card(Map<String, dynamic> row) {
    final id = recordId(row);
    final status = row['status']?.toString();
    final canAct = id.isNotEmpty && !state.saving && !state.loading;
    final course = object(row['course'] ?? row['courseId']);
    final student = object(row['student'] ?? row['studentId']);
    final name = widget.feature == 'enrollments'
        ? title(course)
        : widget.feature == 'reviews'
        ? title(student)
        : title(row);
    final image = row['thumbnailUrl'];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AdminPanel(
        padding: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.feature == 'courses' &&
                image is String &&
                image.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => Container(
                    height: 90,
                    color: const Color(0xFFEDF1E7),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_stories_outlined,
                      color: adminInk,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF1E7),
                    borderRadius: BorderRadius.circular(
                      widget.feature == 'users' ? 22 : 12,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: widget.feature == 'users' && name.isNotEmpty
                      ? Text(
                          name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: adminInk,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Icon(
                          adminIcon(widget.feature),
                          color: adminInk,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty
                            ? (widget.feature == 'reviews'
                                  ? 'Learner feedback'
                                  : 'Untitled record')
                            : name,
                        style: const TextStyle(
                          color: adminInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      if (row['email'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${row['email']}',
                            style: const TextStyle(
                              color: adminMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (widget.feature == 'reviews')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFA9783E),
                                size: 17,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${row['rating'] ?? '—'} / 5',
                                style: const TextStyle(
                                  color: Color(0xFFA9783E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (row['role'] != null) AdminBadge('${row['role']}'),
                if (status != null) AdminBadge(status),
                if (widget.feature == 'categories')
                  AdminBadge(row['isActive'] == true ? 'ACTIVE' : 'INACTIVE'),
                if (widget.feature == 'reviews')
                  AdminBadge(row['isVisible'] == false ? 'HIDDEN' : 'VISIBLE'),
                if (widget.feature == 'courses') ...[
                  if (row['level'] != null) AdminBadge('${row['level']}'),
                  if (row['language'] != null) AdminBadge('${row['language']}'),
                ],
              ],
            ),
            if (widget.feature == 'enrollments') ...[
              const SizedBox(height: 12),
              Text(
                title(student),
                style: const TextStyle(
                  color: adminInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (student['email'] != null) Text('${student['email']}'),
              if (row['progressPercentage'] != null)
                Text('Progress: ${row['progressPercentage']}%'),
              if (row['progressPercentage'] is num) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: const Color(0xFF4C805E),
                    backgroundColor: const Color(0xFFEDF1E7),
                    value: ((row['progressPercentage'] as num) / 100)
                        .clamp(0, 1)
                        .toDouble(),
                  ),
                ),
              ],
            ],
            if (row['shortDescription'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${row['shortDescription']}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            if (row['description'] != null && widget.feature != 'courses')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${row['description']}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: adminMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            if (row['comment'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${row['comment']}',
                  style: const TextStyle(
                    color: adminInk,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ),
            if (widget.feature != 'enrollments' || widget.selecting)
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 2),
                child: Divider(color: adminLine, height: 16),
              ),
            if (widget.selecting)
              TextButton(
                onPressed: canAct ? () => Navigator.pop(context, row) : null,
                child: const Text('Select'),
              ),
            if (!widget.selecting)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (widget.feature == 'users') ...[
                    OutlinedButton(
                      onPressed: canAct ? () => userDetails(id) : null,
                      child: const Text('View details'),
                    ),
                    if (id != recordId(context.read<AuthProvider>().user ?? {}))
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: status == 'ACTIVE'
                              ? const Color(0xFFAF5746)
                              : adminInk,
                        ),
                        onPressed: canAct
                            ? () => action(
                                status == 'ACTIVE'
                                    ? 'Suspend user'
                                    : 'Reactivate user',
                                'users/$id/status',
                                data: {
                                  'status': status == 'ACTIVE'
                                      ? 'SUSPENDED'
                                      : 'ACTIVE',
                                },
                              )
                            : null,
                        child: Text(
                          status == 'ACTIVE' ? 'Suspend' : 'Reactivate',
                        ),
                      ),
                  ],
                  if (widget.feature == 'categories') ...[
                    TextButton(
                      onPressed: canAct ? () => category(row) : null,
                      child: const Text('Edit'),
                    ),
                    TextButton(
                      onPressed: canAct
                          ? () => action(
                              'Change category status',
                              'categories/$id/status',
                              data: {'isActive': row['isActive'] != true},
                            )
                          : null,
                      child: Text(
                        row['isActive'] == true ? 'Deactivate' : 'Activate',
                      ),
                    ),
                  ],
                  if (widget.feature == 'courses') ...[
                    TextButton(
                      onPressed: canAct ? () => inspectCourse(row) : null,
                      child: const Text('Inspect course'),
                    ),
                    TextButton(
                      onPressed: canAct
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => AdminListScreen(
                                  feature: 'reviews',
                                  courseId: id,
                                ),
                              ),
                            )
                          : null,
                      child: const Text('Reviews'),
                    ),
                    if (status != 'ARCHIVED')
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFAF5746),
                        ),
                        onPressed: canAct
                            ? () => action(
                                'Archive course',
                                'courses/$id/admin/archive',
                              )
                            : null,
                        child: const Text('Archive'),
                      ),
                  ],
                  if (widget.feature == 'reviews')
                    TextButton(
                      onPressed: canAct
                          ? () async {
                              final visible = row['isVisible'] != false;
                              if (!await confirmActivity(
                                context,
                                visible ? 'Hide review' : 'Show review',
                                'Update the public visibility of this review?',
                              )) {
                                return;
                              }
                              if (!mounted) return;
                              final ok = await state.mutate(
                                'PATCH',
                                'reviews/$id/visibility',
                                data: {'isVisible': !visible},
                              );
                              if (ok && mounted) {
                                setState(() {
                                  if (visible) {
                                    hiddenReviews[id] = {
                                      ...row,
                                      'isVisible': false,
                                    };
                                  } else {
                                    hiddenReviews.remove(id);
                                  }
                                });
                              }
                            }
                          : null,
                      child: Text(
                        row['isVisible'] == false
                            ? 'Show review'
                            : 'Hide review',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> userDetails(String id) async {
    try {
      final data = object(
        (await state.service.request('GET', 'users/$id'))['data'],
      );
      final user = object(data['user'] ?? data);
      if (!mounted) return;
      await detailSheet(title(user), 'Account details', [
        for (final key in ['email', 'role', 'status', 'bio', 'createdAt'])
          if (user[key] != null)
            AdminField(
              key == 'createdAt' ? 'Joined' : adminLabel(key),
              ['role', 'status'].contains(key)
                  ? adminLabel(user[key])
                  : key == 'createdAt'
                  ? displayDate(user[key])
                  : user[key],
            ),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AuthProvider.message(e))));
      }
    }
  }

  String displayDate(Object? raw) {
    final value = DateTime.tryParse('$raw');
    return value == null
        ? '$raw'
        : MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  Future<void> inspectCourse(Map<String, dynamic> row) =>
      detailSheet(title(row), 'Course overview', [
        if (row['status'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminBadge('${row['status']}'),
            ),
          ),
        for (final key in [
          'description',
          'level',
          'language',
          'learningOutcomes',
          'requirements',
          'createdAt',
        ])
          if (row[key] != null)
            AdminField(
              adminLabel(key),
              row[key] is List
                  ? (row[key] as List).map((value) => '• $value').join('\n')
                  : key == 'createdAt'
                  ? displayDate(row[key])
                  : row[key],
            ),
      ]);

  Future<void> detailSheet(String name, String label, List<Widget> fields) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: adminCanvas,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(color: adminMuted, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    AdminHeading(name),
                    AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: fields,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

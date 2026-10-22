import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/widgets/auth_layout.dart';

import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../../student/learning/widgets/student_learning_summary.dart';
import '../../student/learning/services/learning_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onSignedOut});
  final VoidCallback? onSignedOut;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _busy = true;
  String? _message;
  double? _progress;

  bool _messageIsError = false;
  TextEditingController field(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  // Birthdays are calendar dates: preserve the returned date without a timezone conversion.
  String dateOnly(Object? value) {
    final text = value?.toString() ?? '';
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)
        ? text.substring(0, 10)
        : text;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => run(load));
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
    if (!mounted) return;
    for (final entry in {...?auth.user, ...?auth.profile}.entries) {
      field(entry.key).text = entry.key == 'dateOfBirth'
          ? dateOnly(entry.value)
          : entry.value is List
          ? (entry.value as List).join(', ')
          : entry.value?.toString() ?? '';
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = AuthProvider.message(error);
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Map<String, dynamic> changes(AuthProvider auth, bool shared) {
    final keys = shared
        ? ['firstName', 'lastName', 'bio']
        : auth.role == 'STUDENT'
        ? ['dateOfBirth', 'educationLevel', 'learningGoals']
        : [
            'headline',
            'qualification',
            'experienceYears',
            'expertise',
            'biography',
          ];
    final original = shared ? auth.user : auth.profile;
    final data = <String, dynamic>{};
    for (final key in keys) {
      final text = field(key).text.trim();
      final Object? value = ['learningGoals', 'expertise'].contains(key)
          ? text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : key == 'experienceYears'
          ? int.parse(text)
          : key == 'bio' && text.isEmpty
          ? null
          : text;
      final previous = key == 'dateOfBirth'
          ? dateOnly(original?[key])
          : original?[key];
      if ((previous is List
              ? previous.join(', ')
              : previous?.toString() ?? '') !=
          (value is List ? value.join(', ') : value?.toString() ?? '')) {
        data[key] = value;
      }
    }
    return data;
  }

  Future<void> save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final account = changes(auth, true);
    final role = ['STUDENT', 'INSTRUCTOR'].contains(auth.role)
        ? changes(auth, false)
        : <String, dynamic>{};
    if (account.isEmpty && role.isEmpty) {
      setState(() {
        _message = 'No changes to save.';
        _messageIsError = false;
      });
      return;
    }
    await run(() async {
      var accountSaved = false;
      try {
        if (account.isNotEmpty) {
          await auth.service.request(
            'PATCH',
            '/api/v1/users/me',
            data: account,
          );
          accountSaved = true;
          // Update the saved baseline without discarding unsaved role fields.
          auth.user?.addAll(account);
        }
        if (role.isNotEmpty) {
          await auth.service.request(
            auth.profile == null ? 'POST' : 'PATCH',
            '/api/v1/profiles/${auth.role!.toLowerCase()}/me',
            data: role,
          );
          auth.profile = {...?auth.profile, ...role};
        }
      } catch (error) {
        throw ApiException(
          message: accountSaved
              ? 'Your name and bio were saved, but your profile details were not. ${AuthProvider.message(error)} Your edits are still here; try saving again.'
              : AuthProvider.message(error),
        );
      }
      try {
        await load();
      } catch (_) {
        if (mounted) {
          setState(
            () => _message = 'Changes saved. Could not refresh the display; refresh details when your connection returns.',
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _message = 'All changes saved.');
      }
    });
  }

  Future<void> image(bool delete) async {
    final auth = context.read<AuthProvider>();
    if (delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove profile photo?'),
          content: const Text('Your initials will appear in its place.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await run(() async {
        await auth.service.request('DELETE', '/api/v1/users/me/profile-image');
        await load();
        if (mounted) setState(() => _message = 'Profile photo removed.');
      });
      return;
    }
    await run(() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final mime = lookupMimeType(picked.name, headerBytes: bytes);
      if (!['image/jpeg', 'image/png', 'image/webp'].contains(mime) ||
          bytes.length > 5 * 1024 * 1024) {
        throw const ApiException(
          message: 'Choose a JPEG, PNG or WebP image up to 5 MB.',
        );
      }

      await auth.service.request(
        'POST',
        '/api/v1/users/me/profile-image',
        data: FormData.fromMap({
          'profileImage': MultipartFile.fromBytes(
            bytes,
            filename: picked.name,
            contentType: MediaType.parse(mime!),
          ),
        }),
        progress: (sent, total) {
          if (mounted && total > 0) setState(() => _progress = sent / total);
        },
      );
      await load();
      if (mounted) setState(() => _message = 'Profile photo updated.');
    });
  }

  Future<void> deleteProfile() async {
    final auth = context.read<AuthProvider>();
    if (_busy ||
        !['STUDENT', 'INSTRUCTOR'].contains(auth.role) ||
        auth.profile == null) {
      return;
    }
    final role = auth.role!.toLowerCase();
    if (!await confirmActivity(
      context,
      'Delete $role profile?',
      'Permanently remove your $role profile details? Your account will remain active. You can recreate the profile by saving new details.',
    )) {
      return;
    }
    if (!mounted) return;
    await run(() async {
      await auth.service.request('DELETE', '/api/v1/profiles/$role/me');
      auth.profile = null;
      for (final key in [
        'dateOfBirth',
        'educationLevel',
        'learningGoals',
        'headline',
        'qualification',
        'experienceYears',
        'expertise',
        'biography',
      ]) {
        field(key).clear();
      }
      await load();
      if (mounted) _message = 'Profile deleted. Your account remains active.';
    });
  }

  Future<void> logout(bool all) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(all ? 'Log out all devices?' : 'Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await run(() async {
      await auth.logout(all: all);
      if (mounted) {
        if (widget.onSignedOut != null) {
          widget.onSignedOut!();
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        }
      }
    });
  }

  Widget _initials(AuthProvider auth) {
    final first = (auth.user?['firstName']?.toString() ?? '').trim();
    final last = (auth.user?['lastName']?.toString() ?? '').trim();
    final initials =
        '${first.isEmpty ? '' : first.characters.first}${last.isEmpty ? '' : last.characters.first}'
            .toUpperCase();
    return Center(
      child: initials.isEmpty
          ? const Icon(Icons.person_outline, size: 44)
          : Text(
              initials,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }

  static const educationLevels = [
    'Ordinary Level',
    'Certificate Level',
    'Advanced Level',
    'Diploma',
    'Undergraduate',
    'Postgraduate',
    'Other',
  ];

  Future<void> pickBirthday() async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final existing = DateTime.tryParse(field('dateOfBirth').text);
    final initial =
        existing != null && !existing.isAfter(today) && existing.year >= 1900
        ? existing
        : DateTime(today.year - 18, today.month, today.day);
    final selected = await showDatePicker(
      context: context,
      helpText: 'Select date of birth',
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected == null || !mounted) return;
    setState(
      () => field('dateOfBirth').text =
          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
    );
  }

  Widget profileInput(String key) {
    if (key == 'educationLevel') {
      final current = field(key).text.trim();
      // Preserve backend values outside the standard registration options.
      final options = [
        ...educationLevels,
        if (current.isNotEmpty && !educationLevels.contains(current)) current,
      ];
      return DropdownButtonFormField<String>(
        key: ValueKey('education/$current'),
        initialValue: current.isEmpty ? null : current,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Education level'),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: _busy
            ? null
            : (value) => setState(() => field(key).text = value ?? ''),
        validator: (value) => value == null || value.isEmpty
            ? 'Select your education level.'
            : null,
      );
    }
    final label =
        const {
          'firstName': 'First name',
          'lastName': 'Last name',
          'dateOfBirth': 'Date of birth',
        }[key] ??
        '${key[0].toUpperCase()}${key.substring(1).replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}')}';
    return TextFormField(
      controller: field(key),
      enabled: !_busy,
      keyboardType: key == 'experienceYears'
          ? TextInputType.number
          : TextInputType.text,
      inputFormatters: key == 'experienceYears'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      readOnly: key == 'dateOfBirth',
      onTap: key == 'dateOfBirth' ? pickBirthday : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: key == 'dateOfBirth'
            ? const Icon(Icons.calendar_today_outlined)
            : null,
      ),
      validator: (value) {
        if (['firstName', 'lastName'].contains(key) &&
            (value == null || value.trim().isEmpty)) {
          return 'This field is required.';
        }
        if (key == 'experienceYears' &&
            (int.tryParse(value ?? '') == null || int.parse(value!) < 0)) {
          return 'Enter valid years.';
        }
        if (key == 'dateOfBirth' &&
            (value ?? '').isNotEmpty &&
            DateTime.tryParse(value!) == null) {
          return 'Select a valid date.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roleFields = auth.role == 'STUDENT'
        ? ['dateOfBirth', 'educationLevel', 'learningGoals']
        : auth.role == 'INSTRUCTOR'
        ? [
            'headline',
            'qualification',
            'experienceYears',
            'expertise',
            'biography',
          ]
        : <String>[];
    final imageUrl = auth.user?['profileImageUrl'];
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name =
        '${auth.user?['firstName'] ?? ''} ${auth.user?['lastName'] ?? ''}'
            .trim();
    final hasPhoto = imageUrl is String && imageUrl.isNotEmpty;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123E34), Color(0xFF22735F)],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'MY PROFILE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFB5EAD5),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: imageUrl is String && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, stack) => _initials(auth),
                              )
                            : _initials(auth),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        tooltip: 'Change profile photo',
                        onPressed: _busy ? null : () => image(false),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? 'My profile' : name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${auth.user?['email'] ?? ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD2E7DD)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    auth.role == 'STUDENT'
                        ? 'Student'
                        : auth.role == 'INSTRUCTOR'
                        ? 'Instructor'
                        : 'Administrator',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .4),
                        ),
                      ),
                      onPressed: _busy ? null : () => image(false),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(hasPhoto ? 'Change photo' : 'Choose photo'),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD2E7DD),
                        ),
                        onPressed: _busy ? null : () => image(true),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'JPG, PNG or WebP · Up to 5 MB',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB5D4C8), fontSize: 11),
                ),
                if (_busy)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(value: _progress),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (auth.role == 'STUDENT' &&
              context.watch<LearningService?>() != null) ...[
            const StudentLearningSummary(),
            const SizedBox(height: 20),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AuthFeedback(message: _message!, error: _messageIsError),
            ),
          _ProfileSection(
            icon: Icons.person_outline_rounded,
            title: 'Personal details',
            subtitle: 'A little about you',
            children: [
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 280
                    ? Column(
                        children: [
                          profileInput('firstName'),
                          const SizedBox(height: 16),
                          profileInput('lastName'),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: profileInput('firstName')),
                          const SizedBox(width: 12),
                          Expanded(child: profileInput('lastName')),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              profileInput('bio'),
            ],
          ),
          if (roleFields.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ProfileSection(
              icon: auth.role == 'STUDENT'
                  ? Icons.school_outlined
                  : Icons.work_outline_rounded,
              title: auth.role == 'STUDENT'
                  ? 'Learning profile'
                  : 'Professional details',
              subtitle: auth.role == 'STUDENT'
                  ? 'Your background and learning goals'
                  : 'Share your experience and expertise',
              children: [
                for (var i = 0; i < roleFields.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  profileInput(roleFields[i]),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          AuthSubmitButton(label: 'Save changes', busy: _busy, onPressed: save),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _busy ? null : () => run(load),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh details'),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileSection(
            icon: Icons.shield_outlined,
            title: 'Account & security',
            subtitle: 'Manage your signed-in sessions',
            children: [
              if (['STUDENT', 'INSTRUCTOR'].contains(auth.role) &&
                  auth.profile != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: colors.error),
                  title: const Text('Delete Profile'),
                  subtitle: const Text(
                    'Remove profile details; keep your account',
                  ),
                  onTap: _busy ? null : deleteProfile,
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout_rounded, color: colors.error),
                title: const Text('Log out'),
                subtitle: const Text('Sign out on this device'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _busy ? null : () => logout(false),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.devices_outlined, color: colors.error),
                title: const Text('Log out all devices'),
                subtitle: const Text('Sign out of every active session'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _busy ? null : () => logout(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final IconData icon;
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

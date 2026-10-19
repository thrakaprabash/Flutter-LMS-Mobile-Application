import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/widgets/auth_layout.dart';

import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../core/network/api_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _busy = true;
  String? _message;
  double? _progress;
  Uint8List? _demoPhoto;
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
        setState(
          () => _message = auth.isDemo
              ? 'Demo changes saved locally.'
              : 'All changes saved.',
        );
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
      if (auth.isDemo) {
        setState(() {
          _demoPhoto = null;
          _message = 'Demo photo removed locally.';
          _messageIsError = false;
        });
        return;
      }
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
      if (auth.isDemo) {
        setState(() {
          _demoPhoto = bytes;
          _message = 'Demo photo preview updated. Nothing was uploaded.';
        });
        return;
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
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
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
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('My profile', style: Theme.of(context).textTheme.headlineMedium),
          Text('${auth.user?['email'] ?? ''} · ${auth.role ?? ''}'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
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
                          child: _demoPhoto != null
                              ? Image.memory(_demoPhoto!, fit: BoxFit.cover)
                              : imageUrl is String && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, stack) =>
                                      _initials(auth),
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
                    'Profile photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'JPG, PNG or WebP · Up to 5 MB',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (auth.isDemo)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Demo preview only · Resets when you leave',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => image(false),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _demoPhoto != null ||
                                  (imageUrl is String && imageUrl.isNotEmpty)
                              ? 'Change photo'
                              : 'Choose photo',
                        ),
                      ),
                      if (_demoPhoto != null ||
                          (imageUrl is String && imageUrl.isNotEmpty))
                        TextButton.icon(
                          onPressed: _busy ? null : () => image(true),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                  if (_busy)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(value: _progress),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_message != null)
            AuthFeedback(message: _message!, error: _messageIsError),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _busy ? null : () => run(load),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh details'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: profileInput('firstName')),
                const SizedBox(width: 12),
                Expanded(child: profileInput('lastName')),
              ],
            ),
          ),
          for (final key in ['bio', ...roleFields])
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: profileInput(key),
            ),
          const SizedBox(height: 20),
          AuthSubmitButton(label: 'Save changes', busy: _busy, onPressed: save),
          TextButton(
            onPressed: _busy ? null : () => logout(false),
            child: const Text('Log out'),
          ),
          TextButton(
            onPressed: _busy ? null : () => logout(true),
            child: const Text('Log out all devices'),
          ),
        ],
      ),
    );
  }
}

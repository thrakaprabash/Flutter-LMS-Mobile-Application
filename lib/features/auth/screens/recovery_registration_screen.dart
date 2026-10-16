import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/auth_layout.dart';

import 'package:provider/provider.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../core/utils/validators.dart';

class RecoveryRegistrationScreen extends StatefulWidget {
  const RecoveryRegistrationScreen({
    super.key,
    this.register = false,
    this.verify = false,
    this.initialEmail = '',
  });
  final bool register;
  final bool verify;
  final String initialEmail;
  @override
  State<RecoveryRegistrationScreen> createState() => _AccountFlowState();
}

class _AccountFlowState extends State<RecoveryRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  String _role = 'student';
  late String _step;
  String? _resetToken;
  String? _message;
  bool _busy = false;
  bool _messageIsError = false;
  final _visiblePasswords = <String>{};
  int _cooldown = 0;
  Timer? _timer;
  TextEditingController field(String name) =>
      _fields.putIfAbsent(name, TextEditingController.new);
  String value(String name) => field(name).text.trim();
  @override
  void initState() {
    super.initState();
    field('email').text = widget.initialEmail;
    _step = widget.register
        ? 'register'
        : widget.verify
        ? 'verify-email'
        : 'forgot-password';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _fields.values) {
      c.dispose();
    }
    _resetToken = null;
    super.dispose();
  }

  void cooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown == 0) timer.cancel();
    });
  }

  List<String> get names => switch (_step) {
    'register' => [
      'firstName',
      'lastName',
      'email',
      'password',
      'confirmPassword',
      if (_role == 'student') ...[
        'dateOfBirth',
        'educationLevel',
        'learningGoals',
      ] else ...[
        'headline',
        'qualification',
        'experienceYears',
        'expertise',
        'biography',
      ],
    ],
    'verify-email' || 'verify-password-reset-otp' => ['email', 'otp'],
    'reset-password' => ['newPassword', 'confirmPassword'],
    _ => ['email'],
  };
  Future<void> submit({bool resend = false}) async {
    if (_busy) return;
    if (resend
        ? Validators.email(value('email')) != null
        : !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });
    try {
      final auth = context.read<AuthProvider>();
      final data = <String, dynamic>{};
      for (final name in names) {
        final text = field(name).text;
        if (['learningGoals', 'expertise'].contains(name)) {
          data[name] = text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (name == 'experienceYears') {
          data[name] = int.parse(text);
        } else {
          data[name] = name.toLowerCase().contains('password')
              ? text
              : text.trim();
        }
      }
      if (_step == 'reset-password') data['resetToken'] = _resetToken;
      final operation = resend
          ? 'resend-verification-otp'
          : _step == 'register'
          ? 'register/$_role'
          : _step;
      final response = await auth.service.auth(
        operation,
        resend ? {'email': value('email')} : data,
      );
      if (!mounted) return;
      if (resend) {
        cooldown();
        setState(
          () => _message =
              response['message']?.toString() ?? 'A new code has been sent.',
        );
      } else if (_step == 'verify-email') {
        await auth.accept(response);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, auth.route, (_) => false);
        }
      } else if (_step == 'reset-password') {
        _resetToken = null;
        await auth.invalidate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset. Sign in with your new password.'),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        }
      } else {
        setState(() {
          if (_step == 'register') {
            field('password').clear();
            field('confirmPassword').clear();
            _step = 'verify-email';
            cooldown();
          } else if (_step == 'forgot-password') {
            _step = 'verify-password-reset-otp';
          } else {
            _resetToken = (response['data'] as Map)['resetToken'] as String;
            _step = 'reset-password';
            field('otp').clear();
          }
          _message = response['message']?.toString();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = AuthProvider.message(error);
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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

  Future<void> pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      helpText: 'Select date of birth',
      initialDate:
          DateTime.tryParse(value('dateOfBirth')) ??
          DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (selected == null || !mounted) return;
    setState(() {
      field('dateOfBirth').text =
          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    });
  }

  Widget input(String name) {
    if (name == 'educationLevel') {
      return DropdownButtonFormField<String>(
        key: const ValueKey('register/educationLevel'),
        initialValue: value(name).isEmpty ? null : value(name),
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Education level'),
        items: [
          for (final level in educationLevels)
            DropdownMenuItem(value: level, child: Text(level)),
        ],
        onChanged: _busy
            ? null
            : (level) => setState(() => field(name).text = level ?? ''),
        validator: (level) => level == null || level.isEmpty
            ? 'Select your education level.'
            : null,
      );
    }
    return TextFormField(
      key: ValueKey('$_step/$name'),
      controller: field(name),
      enabled: !_busy,
      readOnly: name == 'dateOfBirth',
      onTap: name == 'dateOfBirth' ? pickDateOfBirth : null,
      obscureText:
          name.toLowerCase().contains('password') &&
          !_visiblePasswords.contains(name),
      autocorrect: false,
      enableSuggestions: !name.toLowerCase().contains('password'),
      textInputAction: name == names.last
          ? TextInputAction.done
          : TextInputAction.next,
      onFieldSubmitted: name == names.last ? (_) => submit() : null,
      inputFormatters: name == 'otp'
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ]
          : name == 'experienceYears'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      autofillHints: name == 'otp'
          ? const [AutofillHints.oneTimeCode]
          : name == 'email'
          ? const [AutofillHints.email]
          : name.toLowerCase().contains('password')
          ? const [AutofillHints.newPassword]
          : null,
      keyboardType: name == 'email'
          ? TextInputType.emailAddress
          : ['otp', 'experienceYears'].contains(name)
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        suffixIcon: name == 'dateOfBirth'
            ? const Icon(Icons.calendar_today_outlined)
            : name.toLowerCase().contains('password')
            ? IconButton(
                tooltip: _visiblePasswords.contains(name)
                    ? 'Hide password'
                    : 'Show password',
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        if (!_visiblePasswords.add(name)) {
                          _visiblePasswords.remove(name);
                        }
                      }),
                icon: Icon(
                  _visiblePasswords.contains(name)
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
        labelText: label(name),
        helperText: ['expertise', 'learningGoals'].contains(name)
            ? 'Separate items with commas'
            : name == 'dateOfBirth'
            ? 'YYYY-MM-DD'
            : null,
      ),
      validator: (v) {
        if (name == 'email') return Validators.email(v);
        if (['biography', 'learningGoals'].contains(name)) {
          return null;
        }
        if (v == null || v.trim().isEmpty) {
          return 'This field is required.';
        }
        if (name == 'experienceYears' &&
            (int.tryParse(v) == null || int.parse(v) < 0)) {
          return 'Enter a valid number of years.';
        }
        if (name == 'dateOfBirth' && DateTime.tryParse(v) == null) {
          return 'Enter a valid date.';
        }
        if (name == 'otp' && !RegExp(r'^\d{6}$').hasMatch(v)) {
          return 'Enter the six-digit code.';
        }
        if (name == 'confirmPassword' &&
            v !=
                field(_step == 'reset-password' ? 'newPassword' : 'password')
                    .text) {
          return 'Passwords must match.';
        }
        if (['password', 'newPassword'].contains(name) && v.length < 8) {
          return 'Use at least 8 characters.';
        }
        return null;
      },
    );
  }

  String label(String name) =>
      const {
        'firstName': 'First name',
        'lastName': 'Last name',
        'email': 'Email address',
        'password': 'Password',
        'confirmPassword': 'Confirm password',
        'newPassword': 'New password',
        'otp': 'Verification code',
        'dateOfBirth': 'Date of birth',
        'educationLevel': 'Education level',
        'learningGoals': 'Learning goals (optional)',
        'headline': 'Professional headline',
        'qualification': 'Qualification',
        'experienceYears': 'Years of experience',
        'expertise': 'Areas of expertise',
        'biography': 'Biography (optional)',
      }[name] ??
      name;

  Widget section(String title, String caption) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final registering = _step == 'register';
    final verifying =
        _step == 'verify-email' || _step == 'verify-password-reset-otp';
    final title = switch (_step) {
      'register' => 'Start your journey',
      'verify-email' => 'Check your inbox',
      'forgot-password' => 'Recover password',
      'verify-password-reset-otp' => 'Enter your reset code',
      _ => 'Set new password',
    };
    final subtitle = switch (_step) {
      'register' => 'A new chapter starts with a few details about you.',
      'verify-email' =>
        'Enter the six-digit code sent to your email to activate your account.',
      'forgot-password' => 'Enter your account email. We will send you a code to reset your password.',
      'verify-password-reset-otp' =>
        'Check your email for a six-digit password reset code.',
      _ => 'Choose a password you have not used before. Use at least 8 characters.',
    };
    return AuthLayout(
      back: true,
      showIcon: !registering,
      title: title,
      subtitle: subtitle,
      icon: registering
          ? Icons.person_add_alt_1_outlined
          : verifying
          ? Icons.mark_email_read_outlined
          : Icons.lock_reset_rounded,
      child: AutofillGroup(
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (registering) ...[
                const Text(
                  'I WANT TO JOIN AS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Account type',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(
                      value: 'instructor',
                      child: Text('Instructor'),
                    ),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _role = v!),
                ),
                section(
                  'Your details',
                  'Use the name you want on your learning profile.',
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: input('firstName')),
                    const SizedBox(width: 12),
                    Expanded(child: input('lastName')),
                  ],
                ),
              ],
              for (final name in names.where(
                (name) => !['firstName', 'lastName'].contains(name),
              )) ...[
                if (registering && name == 'password')
                  section(
                    'Secure your account',
                    'Use at least 8 characters. Keep your password private.',
                  ),
                if (registering &&
                    (name == 'dateOfBirth' || name == 'headline'))
                  section(
                    _role == 'student'
                        ? 'Your learning background'
                        : 'Your teaching background',
                    _role == 'student'
                        ? 'Help us get to know your learning journey.'
                        : 'Introduce your experience and areas of expertise.',
                  ),
                const SizedBox(height: 16),
                input(name),
              ],
              const SizedBox(height: 24),
              if (_message != null)
                AuthFeedback(message: _message!, error: _messageIsError),
              AuthSubmitButton(
                label: switch (_step) {
                  'register' => 'Create account',
                  'verify-email' => 'Verify email',
                  'forgot-password' => 'Send reset code',
                  'verify-password-reset-otp' => 'Verify reset code',
                  _ => 'Reset password',
                },
                busy: _busy,
                onPressed: submit,
              ),
              if (_step == 'verify-email') ...[
                const SizedBox(height: 12),
                const Text(
                  'Did not receive a code? Check your spam folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed: _busy || _cooldown > 0
                      ? null
                      : () => submit(resend: true),
                  child: Text(
                    _cooldown > 0 ? 'Resend in $_cooldown s' : 'Resend code',
                  ),
                ),
              ],
              if (registering) ...[
                const SizedBox(height: 16),
                const Divider(),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

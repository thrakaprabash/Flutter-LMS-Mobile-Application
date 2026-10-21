import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../widgets/auth_layout.dart';
import 'recovery_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _busy = false;
  bool _needsVerification = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void openFlow({bool register = false, bool verify = false}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecoveryRegistrationScreen(
          register: register,
          verify: verify,
          initialEmail: _email.text.trim(),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.accept(
        await auth.service.auth('login', {
          'email': _email.text.trim(),
          'password': _password.text,
        }),
      );
      _password.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, auth.route, (_) => false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = AuthProvider.message(error);
          final data = error is DioException ? error.response?.data : null;
          final code = data is Map ? data['errorCode']?.toString() ?? '' : '';
          _needsVerification =
              code.contains('UNVERIFIED') ||
              code.contains('NOT_VERIFIED') ||
              (_error!.toLowerCase().contains('verif') &&
                  !_error!.toLowerCase().contains('suspend'));
          if (code == 'ACCOUNT_SUSPENDED') _error = 'Your account is suspended. Contact your LMS administrator to restore access.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Welcome back',
    subtitle: 'Sign in to continue your learning journey.',
    icon: Icons.login_rounded,
    child: AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'YOUR ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              enabled: !_busy,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              autofillHints: const [AutofillHints.password],
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter your password.' : null,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: _busy
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : () => openFlow(),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null) AuthFeedback(message: _error!),
            if (_needsVerification)
              TextButton(
                onPressed: _busy ? null : () => openFlow(verify: true),
                child: const Text('Verify email'),
              ),
            AuthSubmitButton(label: 'Log in', busy: _busy, onPressed: _submit),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            const Text('New to Flutter LMS?', textAlign: TextAlign.center),
            TextButton(
              onPressed: _busy ? null : () => openFlow(register: true),
              child: const Text('Create an account'),
            ),
            const Text(
              'One login for students, instructors and admins.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

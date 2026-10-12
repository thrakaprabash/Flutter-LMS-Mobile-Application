import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Day 2 local validation only; no API authentication or session is created.
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // Do not pass credentials through routes or persist preview passwords.
    _password.clear();
    setState(() => _obscurePassword = true);
    Navigator.pushNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Flutter LMS',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.asset(
                      'assets/images/university-students.png',
                      fit: BoxFit.cover,
                      semanticLabel:
                          'University students studying together on campus',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your next chapter\nstarts here.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                const Text('Learn together. Go further.'),
                const SizedBox(height: 24),
                Card(
                  elevation: 8,
                  shadowColor: const Color(0x14285C50),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(
                            title: 'Welcome back',
                            subtitle: 'Your learning journey continues here.',
                          ),
                          const SizedBox(height: 28),
                          AppInputField(
                            controller: _email,
                            label: 'Email address',
                            hint: 'you@example.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = (value ?? '').trim();
                              if (email.isEmpty) {
                                return 'Enter your email address.';
                              }
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AppInputField(
                            controller: _password,
                            label: 'Password',
                            hint: 'Your password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your password.';
                              }
                              if (value.length < 8) {
                                return 'Use at least 8 characters for this preview.';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Add at least one uppercase letter.';
                              }
                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return 'Add at least one lowercase letter.';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return 'Add at least one number.';
                              }
                              if (!RegExp(
                                r'[!@#$%^&*(),.?":{}|<>_+\-=\[\]\\/;~`]',
                              ).hasMatch(value)) {
                                return 'Add at least one special character.';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          PrimaryButton(label: 'Log in', onPressed: _submit),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'For students, instructors and admins',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preview only: use any valid email. Password needs 8+ characters with uppercase, lowercase, a number and a special character. No real credentials needed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

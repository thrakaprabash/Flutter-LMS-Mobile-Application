import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/providers/auth_provider.dart';

import '../../../core/routing/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      final auth = context.read<AuthProvider>();
      await auth.restore();
      if (!mounted) return;
      if (auth.restoreError != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const SessionRestoreScreen()),
        );
        return;
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          auth.authenticated ? auth.route : RouteNames.onboarding,
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF285C50),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.white),
          SizedBox(height: 24),
          Text(
            'Flutter LMS',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'Learn together. Go further.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _pages = [
    (
      'assets/images/onboarding-learn.png',
      'Your next chapter starts here',
      'Discover courses and build new skills, one lesson at a time.',
    ),
    (
      'assets/images/onboarding-together.png',
      'Grow together',
      'Connect learning and teaching through lessons, assignments and feedback.',
    ),
    (
      'assets/images/onboarding-progress.png',
      'Make every step count',
      'Follow your progress and keep your learning goals in sight.',
    ),
  ];
  void _finish() => Navigator.pushNamedAndRemoveUntil(
    context,
    RouteNames.login,
    (_) => false,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _page > 0) {
        _controller.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    },
    child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Flutter LMS')),
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: ShaderMask(
                              blendMode: BlendMode.dstIn,
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white,
                                  Colors.white,
                                  Colors.transparent,
                                ],
                                stops: [0, 0.1, 0.9, 1],
                              ).createShader(bounds),
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white,
                                        Colors.white,
                                        Colors.transparent,
                                      ],
                                      stops: [0, 0.08, 0.92, 1],
                                    ).createShader(bounds),
                                child: Image.asset(
                                  page.$1,
                                  fit: BoxFit.contain,
                                  semanticLabel: const [
                                    'A university student learning with a laptop and books',
                                    'University students studying together',
                                    'A student celebrating learning progress',
                                  ][index],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            page.$2,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(page.$3, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Semantics(
                    label: 'Page ${_page + 1} of 3',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.all(4),
                          width: index == _page ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (_page == 2) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(_page == 2 ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SessionRestoreScreen extends StatelessWidget {
  const SessionRestoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(auth.restoreError ?? 'Restoring session…'),
              if (auth.restoring) const CircularProgressIndicator(),
              FilledButton(
                onPressed: auth.restoring
                    ? null
                    : () async {
                        await auth.restore();
                        if (context.mounted && auth.restoreError == null) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            auth.route,
                            (_) => false,
                          );
                        }
                      },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: auth.restoring
                    ? null
                    : () async {
                        await auth.invalidate();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (_) => false,
                          );
                        }
                      },
                child: const Text('Sign in again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

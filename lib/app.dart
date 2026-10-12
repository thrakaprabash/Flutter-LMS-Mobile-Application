import 'package:flutter/material.dart';

import 'features/auth/presentation/login_screen.dart';

class LmsApp extends StatelessWidget {
  const LmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF285C50)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
      ),
      home: const LoginScreen(),
    );
  }
}

import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF285C50));
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'LmsRoboto',
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFFF6F7F2),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFBF8),
        border: border,
        enabledBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFFDCE3D9)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0E5DC)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF192E28),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Color(0xFF192E28),
        ),
        bodyMedium: TextStyle(height: 1.5, color: Color(0xFF64736C)),
      ),
    );
  }
}

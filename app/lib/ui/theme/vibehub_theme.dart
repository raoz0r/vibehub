import 'package:flutter/material.dart';

class VibeHubTheme {
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate150 = Color(0xFFE2E8F0);
  static const slate200 = Color(0xFFCBD5E1);
  static const slate300 = Color(0xFF94A3B8);
  static const slate400 = Color(0xFF64748B);
  static const slate500 = Color(0xFF3B82F6);
  static const slate600 = Color(0xFF2563EB);
  static const slate700 = Color(0xFF1D4ED8);
  static const slate800 = Color(0xFF0F172A);
  static const slate850 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  /// Global styling shortcut for Links, URLs, paths, and code blocks (monospaced)
  static const monoStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: slate700,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: slate50,

      // Default App-wide Typography fallback: Inter (like body CSS rule)
      fontFamily: 'Inter',

      textTheme: const TextTheme(
        // Display and major page titles: Space Grotesk
        headlineLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: slate900,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: slate850,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: slate850,
        ),
        // Description, body copy, and metadata text: Inter (inherited)
        bodyLarge: TextStyle(fontSize: 15, color: slate400),
        bodyMedium: TextStyle(fontSize: 13, color: slate400),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),

      // ==========================================
      // GLOBAL BUTTON STYLING (CSS classes)
      // ==========================================

      // FilledButton style: Blue background, white text, Space Grotesk w600
      // Used for primary actions like "+ Link Skill", "Register Repository"
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: slate600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // Bit rounded
          ),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),

      // OutlinedButton style: Slate/Blue borders, transparent bg, Space Grotesk w600
      // Used for secondary actions/dismissals
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: slate600,
          side: const BorderSide(color: slate200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),

      // TextButton style: Text-only triggers, no background/border, Space Grotesk w600
      // Used for header actions, inline links, and dismiss triggers
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: slate600,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

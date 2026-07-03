import 'package:flutter/material.dart';

class AppTheme {
  // Common Colors
  static const Color primaryColor = Color(0xFF1A56DB);

  // Dark Palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Light Palette
  static const Color lightTextDark =
      Color(0xFF1F2937); // Your custom 0xff1f2937
  static const Color lightSurfaceVariant =
      Color(0xFFF9FAFB); // Your custom 0xfff9fafb

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        surface: Colors.white,
        onSurface: lightTextDark,
        surfaceContainerHighest: lightSurfaceVariant,
        error: Colors.red,
        errorContainer: Color(0xFFFEF2F2), // red.shade50 equivalent
        onErrorContainer: Colors.red,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      dialogBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: lightTextDark,
        elevation: 0.5,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      dividerColor: Colors.white12,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest:
            darkSurface, // dark uses same surface color for tiles
        error: Colors.red.shade300,
        errorContainer: Color(0x78B71C1C), // red.shade900 with alpha
        onErrorContainer: Colors.red.shade300,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      dialogBackgroundColor: darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

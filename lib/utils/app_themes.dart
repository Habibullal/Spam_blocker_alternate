import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF2563EB), // Modern blue
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(color: Color(0xFF4B5563)),
      titleLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Color(0x1A000000),
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFF1F2937)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1F2937), 
        fontSize: 18, 
        fontWeight: FontWeight.w600
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF7C3AED),
      surface: Colors.white,
      background: Color(0xFFFAFAFA),
      error: Color(0xFFEF4444),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1F2937),
      onBackground: Color(0xFF1F2937),
      onError: Colors.white,
      outline: Color(0xFFE5E7EB),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x1A2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: const Color(0x0A000000),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.transparent,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3B82F6),
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    cardColor: const Color(0xFF1A1A1A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF9FAFB)),
      bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
      titleLarge: TextStyle(color: Color(0xFFF9FAFB), fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      shadowColor: Color(0x1AFFFFFF),
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
      titleTextStyle: TextStyle(
        color: Color(0xFFF9FAFB), 
        fontSize: 18, 
        fontWeight: FontWeight.w600
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF0F0F0F),
      error: Color(0xFFF87171),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF9FAFB),
      onBackground: Color(0xFFF9FAFB),
      onError: Colors.white,
      outline: Color(0xFF374151),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x1A3B82F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: const Color(0x1AFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
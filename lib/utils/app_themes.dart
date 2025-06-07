import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF007BFF),
    scaffoldBackgroundColor: const Color(0xFFF4F6F8),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF333333)),
      bodyMedium: TextStyle(color: Color(0xFF555555)),
      titleLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF007BFF),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
    ),
    colorScheme: const ColorScheme.light(
        primary: Color(0xFF007BFF),
        secondary: Color(0xFF0056b3),
        background: Color(0xFFF4F6F8),
        surface: Colors.white,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4dabf7),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
      titleLarge: TextStyle(color: Color(0xFFE0E0E0), fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
       titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
    ),
     colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4dabf7),
        secondary: Color(0xFF1e88e5),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
    ),
  );
}
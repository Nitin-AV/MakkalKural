import 'package:flutter/material.dart';

class AppTheme {
  static const primaryBlue = Color(0xFF2E5AAC);
  static const lightBlue = Color(0xFF4F7DF3);
  static const background = Color(0xFFF4F6FA);
  static const textDark = Color(0xFF1E2A3A);
  static const textLight = Color(0xFF6B7A90);

  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: background,
    fontFamily: 'Poppins',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}

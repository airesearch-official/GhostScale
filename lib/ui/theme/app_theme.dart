import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Deep black
    primaryColor: const Color(0xFF00FF9D), // Cyberpunk Green
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF9D),
      secondary: Color(0xFFD600FF), // Neon Purple
      surface: Color(0xFF121212),
      // background: Color(0xFF0A0A0A), // Deprecated
      error: Color(0xFFFF0055),
    ),
    textTheme: GoogleFonts.orbitronTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00FF9D),
        foregroundColor: Colors.black,
        textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      titleTextStyle: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFFF5F6FA); // very light blue/gray
  static const Color card = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF4F8FFF); // modern blue
  static const Color accent2 = Color(0xFF00C6AE); // turquoise
  static const Color textPrimary = Color(0xFF22223B); // dark blue/gray
  static const Color textSecondary = Color(0xFF7B8FA1); // soft blue/gray
  static const Color error = Color(0xFFFF4B5C); // deep red
  static const Color success = Color(0xFF00C853); // lime green

  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: background,
    cardColor: card,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: accent2,
      surface: background,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: card,
      elevation: 0,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.montserrat(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    ),
    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      bodyLarge: GoogleFonts.montserrat(color: textPrimary, fontSize: 18),
      bodyMedium: GoogleFonts.montserrat(color: textPrimary, fontSize: 16),
      bodySmall: GoogleFonts.montserrat(color: textSecondary, fontSize: 14),
      titleLarge: GoogleFonts.montserrat(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      hintStyle: GoogleFonts.montserrat(color: textSecondary, fontSize: 16),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: accent,
      unselectedItemColor: textSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.montserrat(),
    ),
    cardTheme: const CardThemeData(
      color: card,
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    iconTheme: const IconThemeData(color: accent, size: 28),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
  );
} 
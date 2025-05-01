// app/ui/theme/app_theme.dart (or similar)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0c0c0c);
  static const Color surface = Color(0xFF161616); // AppBar, input field bg
  static const Color primary = Color(0xFFfcac34); // Orange accent
  static const Color textWhite = Color(0xFFffffff);
  static const Color textBlack = Color(0xFF0c0c0c); // For text on orange bg
  static const Color textGrey = Color(0xFFa0a0a0); // For hints, timestamps
  static const Color incomingBubble = Color(0xFF1f1f1f);
  static const Color errorRed = Colors.redAccent;
}

ThemeData buildDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,

    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textWhite, // Color for icons and title
      elevation: 0, // Flat design
      // titleTextStyle: TextStyle(
      //   fontFamily: 'Onest',
      //   fontSize: 20,
      //   fontWeight: FontWeight.bold,
      //   color: AppColors.textWhite,
      // ),
      iconTheme: IconThemeData(color: AppColors.textWhite), // Back arrow etc.
    ),

    textTheme: TextTheme(
      bodyLarge: GoogleFonts.onest(color: AppColors.textWhite, fontSize: 16),
      bodyMedium: GoogleFonts.onest(color: AppColors.textWhite, fontSize: 14),
      titleLarge: GoogleFonts.onest(
        color: AppColors.textWhite,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: GoogleFonts.onest(
        color: AppColors.textWhite,
        fontWeight: FontWeight.bold,
      ),
      labelLarge: GoogleFonts.onest(
        color: AppColors.textBlack,
        fontWeight: FontWeight.bold,
      ),
      bodySmall: GoogleFonts.onest(color: AppColors.textGrey, fontSize: 12),
    ).apply(bodyColor: AppColors.textWhite, displayColor: AppColors.textWhite),

    iconTheme: const IconThemeData(
      color: AppColors.textWhite, // Default icon color
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textWhite,
      textColor: AppColors.textWhite,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textBlack, // Icon color on FAB
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: GoogleFonts.onest(color: AppColors.textGrey),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.onest(),
      ),
    ),

    dialogBackgroundColor: AppColors.surface, // For dialogs like image viewer
    // Optional: Define color scheme for more granular control
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary, // Can be same or different
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: AppColors.textBlack, // Text on Primary buttons
      onSecondary: AppColors.textBlack,
      onBackground: AppColors.textWhite,
      onSurface: AppColors.textWhite, // Text on surface elements
      error: AppColors.errorRed,
      onError: AppColors.textWhite,
    ),
  );
}

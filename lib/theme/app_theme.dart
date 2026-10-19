import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Oranges
  static const Color primary = Color(0xFFFF5500); // Electric Neon Orange
  static const Color primaryLight = Color(0xFFFF7A29);
  static const Color primaryDark = Color(0xFFCC4400);
  static const Color accentAmber = Color(0xFFFF9E00);
  static const Color orangeGlow = Color(0x66FF5500);

  // Background & Surfaces (Deep Matte Charcoal & Obsidian)
  static const Color bgDark = Color(0xFF0B0B0F); // Deepest obsidian black
  static const Color bgSurface = Color(0xFF14141B); // Card surface
  static const Color bgCard = Color(0xFF1B1B24); // Elevated card
  static const Color bgGlass = Color(0x33252535); // Glassmorphism container
  static const Color borderLight = Color(0x1AFFFFFF); // Subtle 10% white border

  // Text & Accents
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EAE);
  static const Color textMuted = Color(0xFF636375);

  // Functional Colors
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF334B);
  static const Color heartRed = Color(0xFFFF3366);
}

class AppGradients {
  static const LinearGradient primaryOrange = LinearGradient(
    colors: [AppColors.primary, AppColors.accentAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF22222E), Color(0xFF14141B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBanner = LinearGradient(
    colors: [Color(0xFF3B1500), Color(0xFF150C07), AppColors.bgDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassOverlay = LinearGradient(
    colors: [Color(0x30FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accentAmber,
        surface: AppColors.bgSurface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.borderLight,
        thumbColor: Colors.white,
        overlayColor: AppColors.orangeGlow,
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}

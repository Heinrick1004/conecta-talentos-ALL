import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Configuração Material compartilhada por todo o aplicativo.
abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.blue,
      onSecondary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.neutral900,
    ),
    scaffoldBackgroundColor: AppColors.neutral50,
    textTheme: TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        textStyle: AppTextStyles.displayTitle,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: AppTextStyles.sectionTitle,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        textStyle: AppTextStyles.cardTitle,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(textStyle: AppTextStyles.bodyText),
      bodyMedium: GoogleFonts.plusJakartaSans(
        textStyle: AppTextStyles.bodyText,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(textStyle: AppTextStyles.caption),
      labelLarge: GoogleFonts.plusJakartaSans(
        textStyle: AppTextStyles.buttonText,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.navy.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: AppTextStyles.buttonText,
        minimumSize: const Size(48, 52),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.linux: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
        TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal,
        ),
      },
    ),
  );
}

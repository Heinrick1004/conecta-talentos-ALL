import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos tipográficos compartilhados, todos em Plus Jakarta Sans.
abstract final class AppTextStyles {
  static TextStyle get displayTitle => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
  );

  static TextStyle get cardSubtitle => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral600,
  );

  static TextStyle get bodyText => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral900,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral600,
  );

  static TextStyle get badgeText =>
      GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700);

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle get wordmark =>
      GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800);
}

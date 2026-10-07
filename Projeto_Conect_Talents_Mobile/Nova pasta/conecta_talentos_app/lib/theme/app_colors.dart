import 'package:flutter/material.dart';

/// Paleta central da identidade visual ConectaTalentos.
abstract final class AppColors {
  static const primary = Color(0xFFD8431B);
  static const primaryLight = Color(0xFFFDEDE6);
  static const navy = Color(0xFF1B2A4A);
  static const blue = Color(0xFF2F6FE0);
  static const success = Color(0xFF1FAE6B);
  static const info = Color(0xFF3B82F6);
  static const danger = Color(0xFFE5484D);

  static const neutral900 = Color(0xFF20242C);
  static const neutral600 = Color(0xFF68707D);
  static const neutral400 = Color(0xFF9AA1AC);
  static const neutral200 = Color(0xFFE2E5E9);
  static const neutral100 = Color(0xFFF1F3F5);
  static const neutral50 = Color(0xFFF8F9FA);
  static const white = Color(0xFFFFFFFF);

  /// Tons cíclicos para diferenciar visualmente vagas e treinamentos.
  static const cardAccentColors = <Color>[
    Color(0xFFE86A32),
    Color(0xFF8B5CF6),
    Color(0xFF3478D4),
    Color(0xFFE04F5F),
    Color(0xFF22A875),
  ];
}

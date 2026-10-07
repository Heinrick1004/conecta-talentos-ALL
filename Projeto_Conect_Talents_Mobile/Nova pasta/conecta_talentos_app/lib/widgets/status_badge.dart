import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum StatusBadgeType { info, success, danger, neutral }

/// Badge em formato pill para estados de candidaturas e treinamentos.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.text, required this.type, super.key});

  final String text;
  final StatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (type) {
      StatusBadgeType.info => (AppColors.info, const Color(0xFFEAF2FF)),
      StatusBadgeType.success => (AppColors.success, const Color(0xFFE7F7EF)),
      StatusBadgeType.danger => (AppColors.danger, const Color(0xFFFFECEC)),
      StatusBadgeType.neutral => (AppColors.neutral600, AppColors.neutral100),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: AppTextStyles.badgeText.copyWith(color: foreground),
        ),
      ),
    );
  }
}

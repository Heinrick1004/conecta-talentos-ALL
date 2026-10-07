import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Ícone branco em caixa colorida para identificar áreas e categorias.
class IconAvatarBox extends StatelessWidget {
  const IconAvatarBox({
    required IconData icon,
    required Color color,
    double size = 54,
    Key? key,
  }) : this._(icon: icon, color: color, size: size, key: key);

  const IconAvatarBox.initials({
    required String label,
    required Color color,
    double size = 54,
    Key? key,
  }) : this._(label: label, color: color, size: size, key: key);

  const IconAvatarBox._({
    this.icon,
    this.label,
    required this.color,
    required this.size,
    super.key,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: label == null
          ? Icon(icon!, color: AppColors.white, size: size * 0.48)
          : Text(
              label!,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            ),
    );
  }
}

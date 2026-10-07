import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabeçalho padrão com wordmark, notificações e avatar do usuário.
class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.userName,
    this.hasUnreadNotifications = false,
    this.onNotificationsTap,
    super.key,
  });

  final String userName;
  final bool hasUnreadNotifications;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final initial = userName.trim().isEmpty
        ? '?'
        : userName.trim().characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 35,
                  height: 32,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Icon(
                          Icons.person_rounded,
                          size: 23,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.wordmark,
                        children: const [
                          TextSpan(
                            text: 'Conecta',
                            style: TextStyle(color: AppColors.navy),
                          ),
                          TextSpan(
                            text: 'Talentos',
                            style: TextStyle(color: AppColors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notificações',
                onPressed: onNotificationsTap,
                icon: const Icon(Icons.notifications_none_rounded),
                color: AppColors.neutral600,
              ),
              if (hasUnreadNotifications)
                Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

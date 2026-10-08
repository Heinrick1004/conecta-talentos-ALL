import 'package:flutter/material.dart';

import '../data/capacitacoes_data.dart';
import '../services/notificacoes_service.dart';
import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/staggered_list_item.dart';

/// Conteúdos conceituais de inclusão e desenvolvimento profissional.
class CapacitacaoScreen extends StatelessWidget {
  const CapacitacaoScreen({
    this.onNavigationItemSelected,
    this.perfilService,
    this.notificacoesService,
    this.onNotificationsTap,
    super.key,
  });

  final ValueChanged<int>? onNavigationItemSelected;
  final PerfilService? perfilService;
  final NotificacoesService? notificacoesService;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              perfilService: perfilService,
              notificacoesService: notificacoesService,
              onNotificationsTap: onNotificationsTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacitação', style: AppTextStyles.displayTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Temas para desenvolver suas habilidades e ampliar suas perspectivas.',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _BannerDestaque(),
                    const SizedBox(height: 24),
                    Text(
                      'Conteúdos conceituais',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 12),
                    for (var index = 0; index < capacitacoesData.length; index++)
                      StaggeredListItem(
                        key: ValueKey(capacitacoesData[index].titulo),
                        index: index,
                        child: _CardCapacitacao(
                          conteudo: capacitacoesData[index],
                          corDestaque:
                              AppColors.cardAccentColors[index %
                                  AppColors.cardAccentColors.length],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onItemSelected: onNavigationItemSelected ?? (_) {},
      ),
    );
  }
}

class _BannerDestaque extends StatelessWidget {
  const _BannerDestaque();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 218),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryLight, AppColors.white],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -23,
                top: 13,
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 37,
                child: Icon(
                  Icons.school_rounded,
                  size: 94,
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Aprender também é crescer!',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Conheça temas sobre inclusão, diversidade e desenvolvimento profissional.',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardCapacitacao extends StatelessWidget {
  const _CardCapacitacao({
    required this.conteudo,
    required this.corDestaque,
  });

  final CapacitacaoItem conteudo;
  final Color corDestaque;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconAvatarBox(
                icon: conteudo.icone,
                color: corDestaque,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(conteudo.titulo, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 5),
                    Text(
                      conteudo.descricao,
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 15,
                color: AppColors.neutral600,
              ),
              const SizedBox(width: 4),
              Text('${conteudo.modulos} módulos', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

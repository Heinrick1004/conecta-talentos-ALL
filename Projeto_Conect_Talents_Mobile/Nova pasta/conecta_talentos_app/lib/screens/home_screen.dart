import 'package:flutter/material.dart';

import '../mock/mock_vagas.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/staggered_list_item.dart';
import 'detalhes_vaga_screen.dart';

/// Página inicial com uma saudação e vagas recomendadas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({this.onNavigationItemSelected, super.key});

  final ValueChanged<int>? onNavigationItemSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              userName: 'Guilherme',
              hasUnreadNotifications: true,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text('Olá, Guilherme 👋', style: AppTextStyles.displayTitle),
                  const SizedBox(height: 5),
                  Text(
                    'Que bom ter você por aqui!',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _CampoBusca(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Vagas para você',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: abrir a lista completa de vagas.
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver todas',
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < mockVagas.length; index++)
                    StaggeredListItem(
                      key: ValueKey(mockVagas[index].titulo),
                      index: index,
                      child: _CardVaga(
                        vaga: mockVagas[index],
                        onNavigationItemSelected: onNavigationItemSelected,
                        corDestaque:
                            AppColors.cardAccentColors[index %
                                AppColors.cardAccentColors.length],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onItemSelected: onNavigationItemSelected ?? (_) {},
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyText,
        decoration: InputDecoration(
          hintText: 'Buscar vagas',
          hintStyle: AppTextStyles.bodyText.copyWith(
            color: AppColors.neutral600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.neutral600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onSubmitted: (_) {
          // TODO: implementar a busca de vagas.
        },
      ),
    );
  }
}

class _CardVaga extends StatelessWidget {
  const _CardVaga({
    required this.vaga,
    required this.corDestaque,
    this.onNavigationItemSelected,
  });

  final VagaMock vaga;
  final Color corDestaque;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: RadialGradient(
        center: Alignment.topRight,
        radius: 1.8,
        colors: [corDestaque.withValues(alpha: 0.12), AppColors.white],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconAvatarBox.initials(
                label: vaga.sigla,
                color: corDestaque,
                size: 50,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaga.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vaga.empresa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox.square(
                dimension: 38,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: corDestaque.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Ver vaga: ${vaga.titulo}',
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => DetalhesVagaScreen(
                            vaga: vaga,
                            onNavigationItemSelected: onNavigationItemSelected,
                          ),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: corDestaque,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _InfoVaga(icone: Icons.location_on_outlined, texto: vaga.local),
              _InfoVaga(icone: vaga.iconeModalidade, texto: vaga.modalidade),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoVaga extends StatelessWidget {
  const _InfoVaga({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 15, color: AppColors.neutral600),
        const SizedBox(width: 4),
        Text(
          texto,
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

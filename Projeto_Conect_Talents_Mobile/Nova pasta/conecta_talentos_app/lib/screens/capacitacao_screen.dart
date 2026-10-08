import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_capacitacoes.dart';
import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/staggered_list_item.dart';

/// Tela de treinamentos e desenvolvimento profissional.
class CapacitacaoScreen extends StatelessWidget {
  const CapacitacaoScreen({
    this.onNavigationItemSelected,
    this.perfilService,
    super.key,
  });

  final ValueChanged<int>? onNavigationItemSelected;
  final PerfilService? perfilService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(perfilService: perfilService),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capacitação', style: AppTextStyles.displayTitle),
                    const SizedBox(height: 6),
                    Text(
                      'Desenvolva suas habilidades e construa um futuro ainda maior.',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _BannerDestaque(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seus treinamentos',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: abrir a lista completa de treinamentos.
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
                                'Ver todos',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded, size: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < mockCapacitacoes.length;
                      index++
                    )
                      StaggeredListItem(
                        key: ValueKey(mockCapacitacoes[index].titulo),
                        index: index,
                        child: _CardTreinamento(
                          treinamento: mockCapacitacoes[index],
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

class _BannerDestaque extends StatefulWidget {
  const _BannerDestaque();

  @override
  State<_BannerDestaque> createState() => _BannerDestaqueState();
}

class _BannerDestaqueState extends State<_BannerDestaque> {
  bool _pressionado = false;

  void _definirPressionado(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _definirPressionado(true),
      onTapUp: (_) => _definirPressionado(false),
      onTapCancel: () => _definirPressionado(false),
      onTap: () {
        // TODO: navegar para os treinamentos em destaque.
      },
      child: AnimatedScale(
        scale: _pressionado ? 0.985 : 1,
        duration: const Duration(milliseconds: 130),
        child: AppCard(
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
                    padding: const EdgeInsets.fromLTRB(18, 18, 58, 64),
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
                          'Acesse nossos treinamentos e fortaleça seu futuro profissional.',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 15,
                    bottom: 14,
                    child:
                        Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Explorar treinamentos',
                                onPressed: () {
                                  // TODO: abrir os treinamentos em destaque.
                                },
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.07, 1.07),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeInOut,
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTreinamento extends StatefulWidget {
  const _CardTreinamento({
    required this.treinamento,
    required this.corDestaque,
  });

  final TreinamentoMock treinamento;
  final Color corDestaque;

  @override
  State<_CardTreinamento> createState() => _CardTreinamentoState();
}

class _CardTreinamentoState extends State<_CardTreinamento> {
  bool _pressionado = false;

  void _definirPressionado(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final treinamento = widget.treinamento;
    final iniciar = treinamento.progressoPercentual == 0;

    return Semantics(
      button: true,
      label: treinamento.titulo,
      child: GestureDetector(
        onTapDown: (_) => _definirPressionado(true),
        onTapUp: (_) => _definirPressionado(false),
        onTapCancel: () => _definirPressionado(false),
        onTap: () {
          // TODO: navegar para os detalhes deste treinamento.
        },
        child: AnimatedScale(
          scale: _pressionado ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconAvatarBox(
                      icon: treinamento.icone,
                      color: widget.corDestaque,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treinamento.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            treinamento.descricao,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
                    Expanded(
                      child: Text(
                        '${treinamento.progressoPercentual}% concluído',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 15,
                      color: AppColors.neutral600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${treinamento.modulos} módulos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: treinamento.progressoPercentual / 100,
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, progresso, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: progresso,
                              minHeight: 6,
                              backgroundColor: AppColors.neutral100,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: abrir o módulo atual do treinamento.
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
                            iniciar ? 'Começar' : 'Continuar',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

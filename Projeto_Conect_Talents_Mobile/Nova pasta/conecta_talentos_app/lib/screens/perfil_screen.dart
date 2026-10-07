import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_perfil.dart';
import '../mock/mock_usuario.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/staggered_list_item.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'meus_interesses_screen.dart';

/// Tela de perfil do candidato.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({this.imageUrl, this.onNavigationItemSelected, super.key});

  final String? imageUrl;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: mockUsuario,
              builder: (context, child) => AppHeader(
                userName: mockUsuario.nome,
                hasUnreadNotifications: true,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          _AvatarPerfil(imageUrl: imageUrl),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedBuilder(
                                  animation: mockUsuario,
                                  builder: (context, child) => Text(
                                    mockUsuario.nome,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.cardTitle.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    mockPerfil.tipo,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  mockPerfil.bio,
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < mockPerfilEstatisticas.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _CardEstatistica(
                              estatistica: mockPerfilEstatisticas[index],
                              cor:
                                  AppColors.cardAccentColors[index %
                                      AppColors.cardAccentColors.length],
                              index: index,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (var index = 0; index < mockPerfilMenu.length; index++)
                      StaggeredListItem(
                        key: ValueKey(mockPerfilMenu[index].titulo),
                        index: index,
                        child: _ItemMenuPerfil(item: mockPerfilMenu[index]),
                      ),
                    const SizedBox(height: 4),
                    const _BannerFuturo(),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _confirmarSaida(context),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            foregroundColor: AppColors.danger,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            'Sair da conta',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
        currentIndex: 3,
        onItemSelected: onNavigationItemSelected ?? (_) {},
      ),
    );
  }

  Future<void> _confirmarSaida(BuildContext context) async {
    final confirmarSaida = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmarSaida != true || !context.mounted) return;

    // TODO: ao integrar a API, remover token/sessão persistida durante o logout.
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _AvatarPerfil extends StatelessWidget {
  const _AvatarPerfil({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.neutral100,
      child: ClipOval(
        child: SizedBox(
          width: 76,
          height: 76,
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _avatarPlaceholder(),
                )
              : _avatarPlaceholder(),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return const ColoredBox(
      color: AppColors.neutral100,
      child: Icon(Icons.person_rounded, size: 38, color: AppColors.neutral400),
    );
  }
}

class _CardEstatistica extends StatelessWidget {
  const _CardEstatistica({
    required this.estatistica,
    required this.cor,
    required this.index,
  });

  final PerfilEstatisticaMock estatistica;
  final Color cor;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            children: [
              Icon(estatistica.icone, size: 20, color: cor),
              const SizedBox(height: 6),
              Text(
                '${estatistica.valor}',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                estatistica.rotulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 90 * index))
        .fadeIn(duration: const Duration(milliseconds: 280))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
        );
  }
}

class _ItemMenuPerfil extends StatefulWidget {
  const _ItemMenuPerfil({required this.item});

  final PerfilMenuMock item;

  @override
  State<_ItemMenuPerfil> createState() => _ItemMenuPerfilState();
}

class _ItemMenuPerfilState extends State<_ItemMenuPerfil> {
  bool _pressionado = false;

  void _definirPressionado(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.item.titulo,
      child: GestureDetector(
        onTapDown: (_) => _definirPressionado(true),
        onTapUp: (_) => _definirPressionado(false),
        onTapCancel: () => _definirPressionado(false),
        onTap: () {
          if (widget.item.titulo == 'Meu currículo') {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const EditarPerfilScreen(),
              ),
            );
          } else if (widget.item.titulo == 'Meus interesses') {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MeusInteressesScreen(),
              ),
            );
          } else {
            // TODO: abrir a seção correspondente do perfil.
          }
        },
        child: AnimatedScale(
          scale: _pressionado ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          child: AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.item.icone,
                    color: AppColors.navy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.titulo, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 3),
                      Text(
                        widget.item.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerFuturo extends StatefulWidget {
  const _BannerFuturo();

  @override
  State<_BannerFuturo> createState() => _BannerFuturoState();
}

class _BannerFuturoState extends State<_BannerFuturo> {
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
        // TODO: abrir oportunidades de desenvolvimento para o candidato.
      },
      child: AnimatedScale(
        scale: _pressionado ? 0.985 : 1,
        duration: const Duration(milliseconds: 130),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(minHeight: 190),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blue.withValues(alpha: 0.12),
                    AppColors.white,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    top: -32,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 30,
                    child: Icon(
                      Icons.track_changes_rounded,
                      size: 96,
                      color: AppColors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 58, 62),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.track_changes_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Seu futuro começa agora!',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Continue se desenvolvendo e aproveite as oportunidades.',
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
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                tooltip: 'Explorar oportunidades',
                                onPressed: () {
                                  // TODO: abrir as oportunidades recomendadas.
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

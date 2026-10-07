import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_favoritos.dart';
import '../mock/mock_vagas.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';
import 'candidatura_confirmacao_screen.dart';

/// Exibe informações completas de uma vaga selecionada na Home.
class DetalhesVagaScreen extends StatefulWidget {
  const DetalhesVagaScreen({
    required this.vaga,
    this.jaCandidatado = false,
    this.onNavigationItemSelected,
    super.key,
  });

  final VagaMock vaga;
  final bool jaCandidatado;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<DetalhesVagaScreen> createState() => _DetalhesVagaScreenState();
}

class _DetalhesVagaScreenState extends State<DetalhesVagaScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final corDestaque =
        AppColors.cardAccentColors[widget.vaga.indiceDestaque %
            AppColors.cardAccentColors.length];

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.neutral900,
                    ),
                    AnimatedBuilder(
                      animation: mockFavoritos,
                      builder: (context, child) {
                        final favorita = mockFavoritos.contem(widget.vaga);
                        return IconButton(
                          tooltip: favorita
                              ? 'Remover dos interesses'
                              : 'Adicionar aos interesses',
                          onPressed: () {
                            mockFavoritos.alternar(widget.vaga);
                            _scaffoldMessengerKey.currentState!
                              ..removeCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    favorita
                                        ? 'Vaga removida dos interesses'
                                        : 'Vaga adicionada aos interesses',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                          icon: Icon(
                            favorita
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                          color: favorita
                              ? AppColors.primary
                              : AppColors.neutral600,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child:
                      Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppCard(
                                padding: const EdgeInsets.all(18),
                                gradient: RadialGradient(
                                  center: Alignment.topRight,
                                  radius: 1.8,
                                  colors: [
                                    corDestaque.withValues(alpha: 0.12),
                                    AppColors.white,
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    IconAvatarBox.initials(
                                      label: widget.vaga.sigla,
                                      color: corDestaque,
                                      size: 58,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.vaga.titulo,
                                      style: AppTextStyles.displayTitle,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.vaga.empresa,
                                      style: AppTextStyles.cardSubtitle,
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 18,
                                      runSpacing: 8,
                                      children: [
                                        _InformacaoVaga(
                                          icone: Icons.location_on_outlined,
                                          texto: widget.vaga.local,
                                        ),
                                        _InformacaoVaga(
                                          icone: widget.vaga.iconeModalidade,
                                          texto: widget.vaga.modalidade,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.vaga.descricao.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Descrição',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.vaga.descricao,
                                  style: AppTextStyles.bodyText,
                                ),
                              ],
                              if (widget.vaga.requisitos.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Requisitos',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 10),
                                for (final requisito in widget.vaga.requisitos)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 19,
                                            color: corDestaque,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            requisito,
                                            style: AppTextStyles.bodyText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 400))
                          .slideY(
                            begin: 0.04,
                            end: 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: const Border(
                top: BorderSide(color: AppColors.neutral200),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: PrimaryButton(
              label: widget.jaCandidatado
                  ? 'Você já se candidatou'
                  : 'Candidatar-se',
              showArrow: !widget.jaCandidatado,
              onPressed: widget.jaCandidatado
                  ? null
                  : () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CandidaturaConfirmacaoScreen(
                      vaga: widget.vaga,
                      onNavigationItemSelected: widget.onNavigationItemSelected,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _InformacaoVaga extends StatelessWidget {
  const _InformacaoVaga({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: AppColors.neutral600),
        const SizedBox(width: 5),
        Text(
          texto,
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

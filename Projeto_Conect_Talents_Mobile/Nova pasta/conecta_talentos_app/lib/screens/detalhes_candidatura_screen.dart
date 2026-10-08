import 'package:flutter/material.dart';

import '../models/candidatura_model.dart';
import '../services/auth_service.dart';
import '../services/candidaturas_service.dart';
import '../services/favoritos_service.dart';
import '../services/vagas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/candidatura_progress.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'detalhes_vaga_screen.dart';

class DetalhesCandidaturaScreen extends StatelessWidget {
  const DetalhesCandidaturaScreen({
    required this.candidatura,
    required this.authService,
    required this.vagasService,
    required this.favoritosService,
    required this.candidaturasService,
    this.onNavigationItemSelected,
    super.key,
  });

  final CandidaturaModel candidatura;
  final AuthService authService;
  final VagasService vagasService;
  final FavoritosService favoritosService;
  final CandidaturasService candidaturasService;
  final ValueChanged<int>? onNavigationItemSelected;

  StatusBadgeType get _tipoStatus => switch (candidatura.status) {
    CandidaturaStatus.emAnalise => StatusBadgeType.info,
    CandidaturaStatus.selecionado => StatusBadgeType.success,
    CandidaturaStatus.rejeitado => StatusBadgeType.danger,
  };

  String get _dataEnviada {
    final data = candidatura.dataCandidatura;
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vaga = candidatura.vaga;
    final corDestaque =
        AppColors.cardAccentColors[vaga.indiceDestaque %
            AppColors.cardAccentColors.length];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.neutral900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detalhes da candidatura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              candidatura.icone,
                              size: 28,
                              color: corDestaque,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vaga.titulo,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vaga.empresa,
                                    style: AppTextStyles.cardSubtitle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              text: candidatura.textoStatus,
                              type: _tipoStatus,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            _InfoCandidatura(
                              icon: Icons.location_on_outlined,
                              text: vaga.local,
                            ),
                            _InfoCandidatura(
                              icon: vaga.iconeModalidade,
                              text: vaga.modalidade,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Enviada em $_dataEnviada',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Etapas do processo', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 14),
                  AppCard(child: CandidaturaProgress(candidatura: candidatura)),
                  if (vaga.descricao.isNotEmpty ||
                      vaga.requisitos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Sobre a vaga', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 10),
                    if (vaga.descricao.isNotEmpty)
                      Text(vaga.descricao, style: AppTextStyles.bodyText),
                    if (vaga.requisitos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Requisitos', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 10),
                      for (final requisito in vaga.requisitos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: corDestaque,
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: PrimaryButton(
            label: 'Ver vaga',
            showArrow: true,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => DetalhesVagaScreen(
                  vaga: vaga,
                  jaCandidatado: true,
                  authService: authService,
                  vagasService: vagasService,
                  favoritosService: favoritosService,
                  candidaturasService: candidaturasService,
                  onNavigationItemSelected: onNavigationItemSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCandidatura extends StatelessWidget {
  const _InfoCandidatura({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.neutral600),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}

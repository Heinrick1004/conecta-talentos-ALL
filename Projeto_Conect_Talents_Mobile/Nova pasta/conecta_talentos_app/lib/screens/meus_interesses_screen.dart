import 'package:flutter/material.dart';

import '../mock/mock_favoritos.dart';
import '../mock/mock_vagas.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import 'detalhes_vaga_screen.dart';

/// Exibe em memória as vagas salvas pelo candidato.
class MeusInteressesScreen extends StatelessWidget {
  const MeusInteressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.neutral900,
                  ),
                  const SizedBox(width: 4),
                  Text('Meus interesses', style: AppTextStyles.sectionTitle),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: mockFavoritos,
                builder: (context, child) {
                  final vagas = mockFavoritos.vagas;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Vagas que você salvou',
                          style: AppTextStyles.displayTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Encontre facilmente as oportunidades que despertaram seu interesse.',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (vagas.isEmpty)
                          const _EstadoVazio()
                        else
                          for (final vaga in vagas)
                            _CardVagaFavorita(vaga: vaga),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Icon(
            Icons.bookmark_border_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma vaga salva ainda',
            textAlign: TextAlign.center,
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Favorite vagas para encontrá-las facilmente depois.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardVagaFavorita extends StatelessWidget {
  const _CardVagaFavorita({required this.vaga});

  final VagaMock vaga;

  @override
  Widget build(BuildContext context) {
    final corDestaque =
        AppColors.cardAccentColors[vaga.indiceDestaque %
            AppColors.cardAccentColors.length];

    return AppCard(
      key: ValueKey('${vaga.empresa}:${vaga.titulo}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      gradient: RadialGradient(
        center: Alignment.topRight,
        radius: 1.8,
        colors: [corDestaque.withValues(alpha: 0.12), AppColors.white],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DetalhesVagaScreen(vaga: vaga),
            ),
          );
        },
        child: Row(
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
                  Text(vaga.empresa, style: AppTextStyles.cardSubtitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InformacaoVaga(
                        icone: Icons.location_on_outlined,
                        texto: vaga.local,
                      ),
                      _InformacaoVaga(
                        icone: vaga.iconeModalidade,
                        texto: vaga.modalidade,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutral400,
            ),
          ],
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

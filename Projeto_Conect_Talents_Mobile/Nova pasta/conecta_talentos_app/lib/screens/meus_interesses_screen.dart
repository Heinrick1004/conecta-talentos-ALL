import 'package:flutter/material.dart';

import '../mock/mock_vagas.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../services/vagas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import 'detalhes_vaga_screen.dart';

/// Exibe os favoritos persistidos do candidato.
class MeusInteressesScreen extends StatefulWidget {
  const MeusInteressesScreen({
    this.authService,
    this.favoritosService,
    this.vagasService,
    super.key,
  });

  final AuthService? authService;
  final FavoritosService? favoritosService;
  final VagasService? vagasService;

  @override
  State<MeusInteressesScreen> createState() => _MeusInteressesScreenState();
}

class _MeusInteressesScreenState extends State<MeusInteressesScreen> {
  late final AuthService _authService;
  late final FavoritosService _favoritosService;
  late final VagasService _vagasService;
  List<VagaMock> _favoritos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _favoritosService =
        widget.favoritosService ?? FavoritosService(authService: _authService);
    _vagasService =
        widget.vagasService ?? VagasService(authService: _authService);
    _carregarFavoritos();
  }

  Future<void> _carregarFavoritos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final favoritos = await _favoritosService.listarFavoritos();
      if (!mounted) return;
      setState(() {
        _favoritos = favoritos;
        _carregando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.statusCode == 401
            ? error.message
            : 'Não foi possível carregar seus interesses.';
        _carregando = false;
      });
    } on Exception catch (error) {
      debugPrint('Falha ao carregar interesses: $error');
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar seus interesses.';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirDetalhes(VagaMock vaga) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DetalhesVagaScreen(
          vaga: vaga,
          authService: _authService,
          favoritosService: _favoritosService,
          vagasService: _vagasService,
        ),
      ),
    );
    if (mounted) await _carregarFavoritos();
  }

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
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _carregarFavoritos,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
                    if (_carregando)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_erro != null)
                      _EstadoErro(
                        mensagem: _erro!,
                        onTentarNovamente: _carregarFavoritos,
                      )
                    else if (_favoritos.isEmpty)
                      const _EstadoVazio()
                    else
                      for (final vaga in _favoritos)
                        _CardVagaFavorita(
                          vaga: vaga,
                          onTap: () => _abrirDetalhes(vaga),
                        ),
                  ],
                ),
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
            style: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.onTentarNovamente});

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onTentarNovamente,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _CardVagaFavorita extends StatelessWidget {
  const _CardVagaFavorita({required this.vaga, required this.onTap});

  final VagaMock vaga;
  final VoidCallback onTap;

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
        onTap: onTap,
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_favoritos.dart';
import '../mock/mock_vagas.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/candidaturas_service.dart';
import '../services/favoritos_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';
import '../services/vagas_service.dart';
import 'candidatura_confirmacao_screen.dart';

/// Exibe informações completas de uma vaga selecionada na Home.
class DetalhesVagaScreen extends StatefulWidget {
  const DetalhesVagaScreen({
    required this.vaga,
    this.jaCandidatado = false,
    this.authService,
    this.vagasService,
    this.favoritosService,
    this.candidaturasService,
    this.onNavigationItemSelected,
    super.key,
  });

  final VagaMock vaga;
  final bool jaCandidatado;
  final AuthService? authService;
  final VagasService? vagasService;
  final FavoritosService? favoritosService;
  final CandidaturasService? candidaturasService;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<DetalhesVagaScreen> createState() => _DetalhesVagaScreenState();
}

class _DetalhesVagaScreenState extends State<DetalhesVagaScreen> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late VagaMock _vaga;
  late final VagasService _vagasService;
  late final FavoritosService _favoritosService;
  late final CandidaturasService _candidaturasService;
  bool _candidaturaConfirmada = false;
  bool _abrindoConfirmacao = false;
  bool _alterandoFavorito = false;

  bool get _jaCandidatado => _candidaturaConfirmada || _vaga.jaCandidatado;

  @override
  void initState() {
    super.initState();
    _vaga = widget.vaga;
    _candidaturaConfirmada = widget.jaCandidatado || _vaga.jaCandidatado;
    final authService = widget.authService ?? AuthService();
    _vagasService =
        widget.vagasService ?? VagasService(authService: authService);
    _favoritosService =
        widget.favoritosService ?? FavoritosService(authService: authService);
    _candidaturasService =
        widget.candidaturasService ??
        CandidaturasService(authService: authService);
    if (_vaga.id != null) _atualizarVaga();
  }

  Future<void> _alternarFavorito(bool favorita) async {
    if (_alterandoFavorito) return;

    final vagaId = _vaga.id;
    if (vagaId == null) {
      mockFavoritos.alternar(_vaga);
      _mostrarMensagem(
        favorita
            ? 'Vaga removida dos interesses'
            : 'Vaga adicionada aos interesses',
      );
      return;
    }

    setState(() => _alterandoFavorito = true);
    try {
      if (favorita) {
        await _favoritosService.removerFavorito(vagaId);
      } else {
        await _favoritosService.adicionarFavorito(vagaId);
      }
      if (!mounted) return;
      setState(() => _vaga = _vaga.copyWith(favoritada: !favorita));
      _mostrarMensagem(
        favorita
            ? 'Vaga removida dos interesses'
            : 'Vaga adicionada aos interesses',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _mostrarMensagem(
        error.statusCode == 401
            ? error.message
            : 'Não foi possível atualizar seus interesses.',
      );
    } on Exception catch (error) {
      debugPrint('Falha ao atualizar favorito: $error');
      if (!mounted) return;
      _mostrarMensagem('Não foi possível atualizar seus interesses.');
    } finally {
      if (mounted) setState(() => _alterandoFavorito = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    _scaffoldMessengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _atualizarVaga() async {
    try {
      final vagaAtualizada = await _vagasService.obterVaga(_vaga.id!);
      if (!mounted) return;
      setState(
        () => _vaga = vagaAtualizada.copyWith(
          jaCandidatado: _candidaturaConfirmada || vagaAtualizada.jaCandidatado,
        ),
      );
    } on Exception catch (error) {
      debugPrint('Falha ao atualizar detalhes da vaga: $error');
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os dados da vaga.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _abrirConfirmacao() async {
    if (_abrindoConfirmacao || _jaCandidatado) return;
    setState(() => _abrindoConfirmacao = true);
    int? abaSolicitada;
    final candidaturaConfirmada = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CandidaturaConfirmacaoScreen(
          vaga: _vaga,
          candidaturasService: _candidaturasService,
          onNavigationItemSelected: (index) => abaSolicitada = index,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _abrindoConfirmacao = false;
      if (candidaturaConfirmada == true) {
        _candidaturaConfirmada = true;
        _vaga = _vaga.copyWith(jaCandidatado: true);
      }
    });
    if (candidaturaConfirmada != true) return;
    if (abaSolicitada != null && widget.onNavigationItemSelected != null) {
      widget.onNavigationItemSelected!(abaSolicitada!);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final corDestaque =
        AppColors.cardAccentColors[_vaga.indiceDestaque %
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
                        final favorita = _vaga.id != null
                            ? _vaga.favoritada
                            : mockFavoritos.contem(_vaga);
                        return IconButton(
                          tooltip: favorita
                              ? 'Remover dos interesses'
                              : 'Adicionar aos interesses',
                          onPressed: _alterandoFavorito
                              ? null
                              : () => _alternarFavorito(favorita),
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
                                      label: _vaga.sigla,
                                      color: corDestaque,
                                      size: 58,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _vaga.titulo,
                                      style: AppTextStyles.displayTitle,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _vaga.empresa,
                                      style: AppTextStyles.cardSubtitle,
                                    ),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 18,
                                      runSpacing: 8,
                                      children: [
                                        _InformacaoVaga(
                                          icone: Icons.location_on_outlined,
                                          texto: _vaga.local,
                                        ),
                                        _InformacaoVaga(
                                          icone: _vaga.iconeModalidade,
                                          texto: _vaga.modalidade,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (_vaga.descricao.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Descrição',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _vaga.descricao,
                                  style: AppTextStyles.bodyText,
                                ),
                              ],
                              if (_vaga.requisitos.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Requisitos',
                                  style: AppTextStyles.sectionTitle,
                                ),
                                const SizedBox(height: 10),
                                for (final requisito in _vaga.requisitos)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
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
              label: _jaCandidatado ? 'Você já se candidatou' : 'Candidatar-se',
              showArrow: !_jaCandidatado,
              onPressed: _jaCandidatado || _abrindoConfirmacao
                  ? null
                  : _abrirConfirmacao,
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

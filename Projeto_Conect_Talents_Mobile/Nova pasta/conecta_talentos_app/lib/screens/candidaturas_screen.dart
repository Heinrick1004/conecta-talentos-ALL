import 'package:flutter/material.dart';

import '../models/candidatura_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/candidaturas_service.dart';
import '../services/favoritos_service.dart';
import '../services/vagas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/candidatura_progress.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/status_badge.dart';
import 'detalhes_candidatura_screen.dart';

/// Tela de acompanhamento das candidaturas do usuário.
class CandidaturasScreen extends StatefulWidget {
  const CandidaturasScreen({
    this.authService,
    this.vagasService,
    this.favoritosService,
    this.candidaturasService,
    this.isActive = true,
    this.onNavigationItemSelected,
    super.key,
  });

  final AuthService? authService;
  final VagasService? vagasService;
  final FavoritosService? favoritosService;
  final CandidaturasService? candidaturasService;
  final bool isActive;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<CandidaturasScreen> createState() => _CandidaturasScreenState();
}

class _CandidaturasScreenState extends State<CandidaturasScreen> {
  static const _filtros = <({String label, CandidaturaStatus? status})>[
    (label: 'Todas', status: null),
    (label: 'Em análise', status: CandidaturaStatus.emAnalise),
    (label: 'Selecionado', status: CandidaturaStatus.selecionado),
    (label: 'Rejeitado', status: CandidaturaStatus.rejeitado),
  ];

  late final AuthService _authService;
  late final VagasService _vagasService;
  late final FavoritosService _favoritosService;
  late final CandidaturasService _candidaturasService;
  List<CandidaturaModel> _candidaturas = [];
  bool _carregando = true;
  String? _erro;
  int _filtroSelecionado = 0;
  int _carregamentoAtual = 0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _vagasService =
        widget.vagasService ?? VagasService(authService: _authService);
    _favoritosService =
        widget.favoritosService ?? FavoritosService(authService: _authService);
    _candidaturasService =
        widget.candidaturasService ??
        CandidaturasService(authService: _authService);
    _carregarCandidaturas();
  }

  @override
  void didUpdateWidget(covariant CandidaturasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _carregarCandidaturas();
    }
  }

  Future<void> _carregarCandidaturas() async {
    final carregamento = ++_carregamentoAtual;
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final candidaturas = await _candidaturasService.listarCandidaturas();
      if (!mounted || carregamento != _carregamentoAtual) return;
      setState(() {
        _candidaturas = candidaturas;
        _carregando = false;
      });
    } on ApiException catch (error) {
      if (!mounted || carregamento != _carregamentoAtual) return;
      setState(() {
        _erro = error.statusCode == 401
            ? error.message
            : 'Não foi possível carregar suas candidaturas.';
        _carregando = false;
      });
    } on Exception catch (error) {
      debugPrint('Falha ao carregar candidaturas: $error');
      if (!mounted || carregamento != _carregamentoAtual) return;
      setState(() {
        _erro = 'Não foi possível carregar suas candidaturas.';
        _carregando = false;
      });
    }
  }

  List<CandidaturaModel> get _candidaturasFiltradas {
    final status = _filtros[_filtroSelecionado].status;
    if (status == null) return _candidaturas;
    return _candidaturas
        .where((candidatura) => candidatura.status == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final candidaturas = _candidaturasFiltradas;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              userName: 'Candidato',
              hasUnreadNotifications: true,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _carregarCandidaturas,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      'Minhas candidaturas',
                      style: AppTextStyles.displayTitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acompanhe o status das suas candidaturas.',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildFiltros(),
                    const SizedBox(height: 18),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              _erro!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _carregarCandidaturas,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    else if (_candidaturas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              size: 36,
                              color: AppColors.neutral600,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Você ainda não possui candidaturas.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyText,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Candidate-se a uma vaga para acompanhar o processo por aqui.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyText.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (candidaturas.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Nenhuma candidatura encontrada para este filtro.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      )
                    else
                      for (var index = 0; index < candidaturas.length; index++)
                        StaggeredListItem(
                          key: ValueKey(
                            '${_filtroSelecionado}_${candidaturas[index].id}',
                          ),
                          index: index,
                          child: _CardCandidatura(
                            candidatura: candidaturas[index],
                            corDestaque:
                                AppColors.cardAccentColors[candidaturas[index]
                                        .vaga
                                        .indiceDestaque %
                                    AppColors.cardAccentColors.length],
                            authService: _authService,
                            vagasService: _vagasService,
                            favoritosService: _favoritosService,
                            candidaturasService: _candidaturasService,
                            onNavigationItemSelected:
                                widget.onNavigationItemSelected,
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
        currentIndex: 1,
        onItemSelected: widget.onNavigationItemSelected ?? (_) {},
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < _filtros.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            _FiltroChip(
              label: '${_filtros[index].label} (${_contagemFiltro(index)})',
              selecionado: _filtroSelecionado == index,
              onTap: () => setState(() => _filtroSelecionado = index),
            ),
          ],
        ],
      ),
    );
  }

  int _contagemFiltro(int index) {
    final status = _filtros[index].status;
    return status == null
        ? _candidaturas.length
        : _candidaturas.where((item) => item.status == status).length;
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selecionado ? AppColors.primary : AppColors.neutral200,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.caption.copyWith(
              color: selecionado ? AppColors.white : AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}

class _CardCandidatura extends StatefulWidget {
  const _CardCandidatura({
    required this.candidatura,
    required this.corDestaque,
    required this.authService,
    required this.vagasService,
    required this.favoritosService,
    required this.candidaturasService,
    required this.onNavigationItemSelected,
  });

  final CandidaturaModel candidatura;
  final Color corDestaque;
  final AuthService authService;
  final VagasService vagasService;
  final FavoritosService favoritosService;
  final CandidaturasService candidaturasService;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<_CardCandidatura> createState() => _CardCandidaturaState();
}

class _CardCandidaturaState extends State<_CardCandidatura> {
  bool _pressionado = false;

  CandidaturaModel get candidatura => widget.candidatura;

  void _definirPressionado(bool valor) {
    if (_pressionado == valor) return;
    setState(() => _pressionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${candidatura.titulo}, ${candidatura.empresa}',
      child: GestureDetector(
        onTapDown: (_) => _definirPressionado(true),
        onTapUp: (_) => _definirPressionado(false),
        onTapCancel: () => _definirPressionado(false),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => DetalhesCandidaturaScreen(
              candidatura: candidatura,
              authService: widget.authService,
              vagasService: widget.vagasService,
              favoritosService: widget.favoritosService,
              candidaturasService: widget.candidaturasService,
              onNavigationItemSelected: widget.onNavigationItemSelected,
            ),
          ),
        ),
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
                      icon: candidatura.icone,
                      color: widget.corDestaque,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    candidatura.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(
                                text: candidatura.textoStatus,
                                type: _tipoStatus(candidatura.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            candidatura.empresa,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoCandidatura(
                      icone: Icons.location_on_outlined,
                      texto: candidatura.local,
                    ),
                    _InfoCandidatura(
                      icone: candidatura.vaga.iconeModalidade,
                      texto: candidatura.modalidade,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CandidaturaProgress(candidatura: candidatura),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StatusBadgeType _tipoStatus(CandidaturaStatus status) => switch (status) {
    CandidaturaStatus.emAnalise => StatusBadgeType.info,
    CandidaturaStatus.selecionado => StatusBadgeType.success,
    CandidaturaStatus.rejeitado => StatusBadgeType.danger,
  };
}

class _InfoCandidatura extends StatelessWidget {
  const _InfoCandidatura({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 15, color: AppColors.neutral600),
        const SizedBox(width: 4),
        Text(texto, style: AppTextStyles.caption),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/perfil_model.dart';
import '../services/auth_service.dart';
import '../services/candidaturas_service.dart';
import '../services/favoritos_service.dart';
import '../services/perfil_service.dart';
import '../services/vagas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/staggered_list_item.dart';
import 'editar_perfil_screen.dart';
import 'login_screen.dart';
import 'meus_interesses_screen.dart';

/// Perfil e contagens associados à conta autenticada do candidato.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({
    required this.perfilService,
    this.authService,
    this.favoritosService,
    this.vagasService,
    this.candidaturasService,
    this.isActive = true,
    this.onNavigationItemSelected,
    super.key,
  });

  final PerfilService perfilService;
  final AuthService? authService;
  final FavoritosService? favoritosService;
  final VagasService? vagasService;
  final CandidaturasService? candidaturasService;
  final bool isActive;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  static const _menu = <({String titulo, String descricao, IconData icone})>[
    (
      titulo: 'Meu currículo',
      descricao: 'Visualize e edite suas informações.',
      icone: Icons.description_outlined,
    ),
    (
      titulo: 'Meus interesses',
      descricao: 'Confira as vagas que você salvou.',
      icone: Icons.favorite_border_rounded,
    ),
    (
      titulo: 'Notificações',
      descricao: 'Acompanhe novidades e atualizações.',
      icone: Icons.notifications_none_rounded,
    ),
    (
      titulo: 'Configurações',
      descricao: 'Ajuste sua conta e preferências.',
      icone: Icons.settings_outlined,
    ),
  ];

  late final AuthService _authService;
  late final FavoritosService _favoritosService;
  late final VagasService _vagasService;
  late final CandidaturasService _candidaturasService;
  int? _totalCandidaturas;
  int? _totalInteresses;
  int _carregamentoEstatisticas = 0;
  bool _dialogoSaidaAberto = false;
  bool _editando = false;
  bool _saindo = false;
  bool _sessaoEncerrada = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _favoritosService =
        widget.favoritosService ?? FavoritosService(authService: _authService);
    _vagasService =
        widget.vagasService ?? VagasService(authService: _authService);
    _candidaturasService =
        widget.candidaturasService ??
        CandidaturasService(authService: _authService);
    _agendarCarregamentoPerfil();
    if (widget.isActive) _carregarEstatisticas();
  }

  @override
  void didUpdateWidget(covariant PerfilScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _agendarCarregamentoPerfil();
      _carregarEstatisticas();
    }
  }

  void _agendarCarregamentoPerfil() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_sessaoEncerrada) _carregarPerfil();
    });
  }

  Future<void> _carregarPerfil({bool forceRefresh = false}) async {
    try {
      await widget.perfilService.carregarPerfil(forceRefresh: forceRefresh);
    } on Exception {
      // O serviço compartilha o estado do erro com todas as telas.
    }
  }

  Future<void> _carregarEstatisticas() async {
    final carregamento = ++_carregamentoEstatisticas;
    setState(() {
      _totalCandidaturas = null;
      _totalInteresses = null;
    });

    Future<void> carregarContagem(
      Future<int> Function() carregar,
      void Function(int?) atualizar,
    ) async {
      int? total;
      try {
        total = await carregar();
      } on Exception {
        // Uma contagem indisponível não impede o uso do perfil.
      }
      if (!mounted ||
          _sessaoEncerrada ||
          carregamento != _carregamentoEstatisticas) {
        return;
      }
      setState(() => atualizar(total));
    }

    await Future.wait([
      carregarContagem(
        () async => (await _candidaturasService.listarCandidaturas()).length,
        (total) => _totalCandidaturas = total,
      ),
      carregarContagem(
        () async => (await _favoritosService.listarFavoritos()).length,
        (total) => _totalInteresses = total,
      ),
    ]);
  }

  Future<void> _atualizarPerfil() async {
    await Future.wait([
      _carregarPerfil(forceRefresh: true),
      _carregarEstatisticas(),
    ]);
  }

  Future<void> _abrirEditor() async {
    final perfil = widget.perfilService.perfil;
    if (perfil == null || _editando) return;
    setState(() => _editando = true);
    PerfilModel? atualizado;
    try {
      atualizado = await Navigator.of(context).push<PerfilModel>(
        MaterialPageRoute<PerfilModel>(
          builder: (_) => EditarPerfilScreen(
            perfil: perfil,
            perfilService: widget.perfilService,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _editando = false);
    }
    if (!mounted || atualizado == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
  }

  Future<void> _abrirInteresses() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MeusInteressesScreen(
          authService: _authService,
          favoritosService: _favoritosService,
          vagasService: _vagasService,
          candidaturasService: _candidaturasService,
          onNavigationItemSelected: widget.onNavigationItemSelected,
        ),
      ),
    );
    if (mounted && !_sessaoEncerrada) await _carregarEstatisticas();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.perfilService,
      builder: (context, child) {
        final perfil = widget.perfilService.perfil;
        final erro = widget.perfilService.erro;
        final mensagemErro = erro == 'Sua sessão expirou. Faça login novamente.'
            ? erro
            : 'Não foi possível carregar seu perfil.';

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppHeader(perfilService: widget.perfilService),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _atualizarPerfil,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        if (perfil == null && erro == null)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (erro != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Text(
                                  mensagemErro ??
                                      'Não foi possível carregar seu perfil.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyText.copyWith(
                                    color: AppColors.neutral600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _atualizarPerfil,
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        if (perfil != null) ...[
                          if (widget.perfilService.carregando)
                            const LinearProgressIndicator(
                              color: AppColors.primary,
                            ),
                          _CardPerfil(perfil: perfil),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _CardEstatistica(
                                  rotulo: 'Candidaturas',
                                  valor: _totalCandidaturas,
                                  icone: Icons.work_outline_rounded,
                                  cor: AppColors.cardAccentColors[0],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CardEstatistica(
                                  rotulo: 'Interesses',
                                  valor: _totalInteresses,
                                  icone: Icons.favorite_border_rounded,
                                  cor: AppColors.cardAccentColors[1],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CardEstatistica(
                                  rotulo: 'Habilidades',
                                  valor: perfil.listaHabilidades.length,
                                  icone: Icons.stars_outlined,
                                  cor: AppColors.cardAccentColors[2],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        for (var index = 0; index < _menu.length; index++)
                          StaggeredListItem(
                            key: ValueKey(_menu[index].titulo),
                            index: index,
                            child: _ItemMenuPerfil(
                              titulo: _menu[index].titulo,
                              descricao: _menu[index].descricao,
                              icone: _menu[index].icone,
                              onTap: switch (index) {
                                0 =>
                                  perfil == null || _saindo || _editando
                                      ? null
                                      : _abrirEditor,
                                1 => _saindo ? null : _abrirInteresses,
                                _ => null,
                              },
                            ),
                          ),
                        const SizedBox(height: 4),
                        const _BannerFuturo(),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _saindo ? null : _confirmarSaida,
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
                                _saindo ? 'Saindo...' : 'Sair da conta',
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
            onItemSelected: widget.onNavigationItemSelected ?? (_) {},
          ),
        );
      },
    );
  }

  Future<void> _confirmarSaida() async {
    if (_dialogoSaidaAberto || _saindo) return;
    _dialogoSaidaAberto = true;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    _dialogoSaidaAberto = false;
    if (!mounted || confirmar != true) return;
    setState(() => _saindo = true);
    try {
      await _authService.logout();
    } on Exception {
      if (!mounted) return;
      setState(() => _saindo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível encerrar a sessão.')),
      );
      return;
    }
    if (!mounted) return;
    _sessaoEncerrada = true;
    _carregamentoEstatisticas++;
    widget.perfilService.limparPerfil();
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(authService: _authService),
      ),
      (route) => false,
    );
  }
}

class _CardPerfil extends StatelessWidget {
  const _CardPerfil({required this.perfil});

  final PerfilModel perfil;

  @override
  Widget build(BuildContext context) {
    final inicial = perfil.nomeCompleto.trim().characters.first.toUpperCase();
    return AppCard(
      key: const Key('perfil-dados'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              inicial,
              style: AppTextStyles.displayTitle.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.nomeCompleto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 20),
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
                    'Candidato',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  perfil.email,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                if (perfil.localidade.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(perfil.localidade, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEstatistica extends StatelessWidget {
  const _CardEstatistica({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  final String rotulo;
  final int? valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('perfil-estatistica-$rotulo'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Column(
        children: [
          Icon(icone, size: 20, color: cor),
          const SizedBox(height: 6),
          Text(
            valor?.toString() ?? '—',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 22,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ItemMenuPerfil extends StatelessWidget {
  const _ItemMenuPerfil({
    required this.titulo,
    required this.descricao,
    required this.icone,
    this.onTap,
  });

  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
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
                child: Icon(icone, color: AppColors.navy, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.neutral400,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerFuturo extends StatelessWidget {
  const _BannerFuturo();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      gradient: LinearGradient(
        colors: [AppColors.blue.withValues(alpha: 0.12), AppColors.white],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.track_changes_rounded,
            color: AppColors.blue,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text('Seu futuro começa agora!', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            'Continue se desenvolvendo e aproveite as oportunidades.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

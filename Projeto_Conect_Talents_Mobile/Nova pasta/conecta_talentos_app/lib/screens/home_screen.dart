import 'package:flutter/material.dart';

import '../mock/mock_vagas.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/vagas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/staggered_list_item.dart';
import 'detalhes_vaga_screen.dart';

/// Página inicial com uma saudação e vagas recomendadas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.authService,
    this.vagasService,
    this.onNavigationItemSelected,
    super.key,
  });

  final AuthService authService;
  final VagasService? vagasService;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VagasService _vagasService;
  final _buscaController = TextEditingController();
  List<VagaMock> _vagas = [];
  String _busca = '';
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _vagasService =
        widget.vagasService ?? VagasService(authService: widget.authService);
    _carregarVagas();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarVagas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final vagas = await _vagasService.listarVagas();
      if (!mounted) return;
      setState(() {
        _vagas = vagas;
        _carregando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.statusCode == 401
            ? error.message
            : 'Não foi possível carregar as vagas.';
        _carregando = false;
      });
    } on Exception catch (error) {
      debugPrint('Falha ao carregar vagas: $error');
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as vagas.';
        _carregando = false;
      });
    }
  }

  List<VagaMock> get _vagasFiltradas {
    final busca = _buscarNormalizado(_busca);
    if (busca.isEmpty) return _vagas;
    return _vagas
        .where((vaga) {
          final campos = [
            vaga.titulo,
            vaga.empresa,
            vaga.local,
            vaga.modalidade,
          ];
          return campos.any(
            (campo) => _buscarNormalizado(campo).contains(busca),
          );
        })
        .toList(growable: false);
  }

  String _buscarNormalizado(String valor) => valor.trim().toLowerCase();

  void _limparBusca() {
    _buscaController.clear();
    setState(() => _busca = '');
  }

  @override
  Widget build(BuildContext context) {
    final vagasFiltradas = _vagasFiltradas;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(
              userName: 'Guilherme',
              hasUnreadNotifications: true,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _carregarVagas,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      'Olá, Guilherme 👋',
                      style: AppTextStyles.displayTitle,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Que bom ter você por aqui!',
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _CampoBusca(
                      controller: _buscaController,
                      onChanged: (value) => setState(() => _busca = value),
                    ),
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
                          onPressed: _limparBusca,
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
                              onPressed: _carregarVagas,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    else if (_vagas.isEmpty)
                      const _MensagemVagas(
                        icone: Icons.work_outline_rounded,
                        mensagem: 'Nenhuma vaga disponível no momento.',
                      )
                    else if (vagasFiltradas.isEmpty)
                      const _MensagemVagas(
                        icone: Icons.search_off_rounded,
                        mensagem: 'Nenhuma vaga encontrada para sua busca.',
                      )
                    else
                      for (
                        var index = 0;
                        index < vagasFiltradas.length;
                        index++
                      )
                        StaggeredListItem(
                          key: ValueKey(
                            vagasFiltradas[index].id ??
                                vagasFiltradas[index].titulo,
                          ),
                          index: index,
                          child: _CardVaga(
                            vaga: vagasFiltradas[index],
                            authService: widget.authService,
                            vagasService: _vagasService,
                            onNavigationItemSelected:
                                widget.onNavigationItemSelected,
                            corDestaque:
                                AppColors.cardAccentColors[vagasFiltradas[index]
                                        .indiceDestaque %
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
        currentIndex: 0,
        onItemSelected: widget.onNavigationItemSelected ?? (_) {},
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

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
        key: const Key('vacancy-search'),
        controller: controller,
        onChanged: onChanged,
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
      ),
    );
  }
}

class _MensagemVagas extends StatelessWidget {
  const _MensagemVagas({required this.icone, required this.mensagem});

  final IconData icone;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(icone, size: 36, color: AppColors.neutral600),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

class _CardVaga extends StatelessWidget {
  const _CardVaga({
    required this.vaga,
    required this.corDestaque,
    required this.authService,
    required this.vagasService,
    this.onNavigationItemSelected,
  });

  final VagaMock vaga;
  final Color corDestaque;
  final AuthService authService;
  final VagasService vagasService;
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
                            authService: authService,
                            vagasService: vagasService,
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

import 'package:flutter/material.dart';

import 'candidaturas_screen.dart';
import 'capacitacao_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import '../services/auth_service.dart';
import '../services/candidaturas_service.dart';
import '../services/favoritos_service.dart';
import '../services/perfil_service.dart';
import '../services/vagas_service.dart';

/// Mantém as quatro abas montadas e conserva o estado de cada tela.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    this.authService,
    this.vagasService,
    this.favoritosService,
    this.candidaturasService,
    this.perfilService,
    super.key,
  });

  final AuthService? authService;
  final VagasService? vagasService;
  final FavoritosService? favoritosService;
  final CandidaturasService? candidaturasService;
  final PerfilService? perfilService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final AuthService _authService;
  late final VagasService _vagasService;
  late final FavoritosService _favoritosService;
  late final CandidaturasService _candidaturasService;
  late final PerfilService _perfilService;
  int _selectedIndex = 0;

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
    _perfilService =
        widget.perfilService ?? PerfilService(authService: _authService);
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      await _perfilService.carregarPerfil();
    } on Exception {
      // O perfil apresenta o erro e permite tentar novamente na sua própria aba.
    }
  }

  @override
  void dispose() {
    if (widget.perfilService == null) _perfilService.dispose();
    super.dispose();
  }

  void _selecionarAba(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(
          authService: _authService,
          vagasService: _vagasService,
          favoritosService: _favoritosService,
          candidaturasService: _candidaturasService,
          perfilService: _perfilService,
          onNavigationItemSelected: _selecionarAba,
        ),
        CandidaturasScreen(
          authService: _authService,
          vagasService: _vagasService,
          favoritosService: _favoritosService,
          candidaturasService: _candidaturasService,
          perfilService: _perfilService,
          isActive: _selectedIndex == 1,
          onNavigationItemSelected: _selecionarAba,
        ),
        CapacitacaoScreen(
          perfilService: _perfilService,
          onNavigationItemSelected: _selecionarAba,
        ),
        PerfilScreen(
          authService: _authService,
          favoritosService: _favoritosService,
          vagasService: _vagasService,
          candidaturasService: _candidaturasService,
          perfilService: _perfilService,
          isActive: _selectedIndex == 3,
          onNavigationItemSelected: _selecionarAba,
        ),
      ],
    );
  }
}

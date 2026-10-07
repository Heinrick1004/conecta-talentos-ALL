import 'package:flutter/material.dart';

import 'candidaturas_screen.dart';
import 'capacitacao_screen.dart';
import 'home_screen.dart';
import 'perfil_screen.dart';
import '../services/auth_service.dart';

/// Mantém as quatro abas montadas e conserva o estado de cada tela.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _selecionarAba(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(onNavigationItemSelected: _selecionarAba),
        CandidaturasScreen(onNavigationItemSelected: _selecionarAba),
        CapacitacaoScreen(onNavigationItemSelected: _selecionarAba),
        PerfilScreen(
          authService: widget.authService,
          onNavigationItemSelected: _selecionarAba,
        ),
      ],
    );
  }
}

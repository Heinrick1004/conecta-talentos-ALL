import 'package:flutter/material.dart';

import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({this.authService, super.key});

  final AuthService? authService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;
  late Future<bool> _sessaoValida;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _sessaoValida = _authService.possuiSessaoValida();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConectaTalentos',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _sessaoValida,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _CarregandoSessao();
          }
          if (snapshot.hasError) {
            return _ErroRestauracaoSessao(
              onTentarNovamente: () {
                setState(() {
                  _sessaoValida = _authService.possuiSessaoValida();
                });
              },
            );
          }
          return snapshot.data == true
              ? MainNavigationScreen(authService: _authService)
              : LoginScreen(authService: _authService);
        },
      ),
    );
  }
}

class _CarregandoSessao extends StatelessWidget {
  const _CarregandoSessao();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _ErroRestauracaoSessao extends StatelessWidget {
  const _ErroRestauracaoSessao({required this.onTentarNovamente});

  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível restaurar sua sessão.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: onTentarNovamente,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

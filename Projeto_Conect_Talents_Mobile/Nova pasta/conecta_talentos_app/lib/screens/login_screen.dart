import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'cadastro_screen.dart';
import 'main_navigation_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';

/// Tela de autenticação para usuários ainda não autenticados.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthService _authService;
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final alturaCard = constraints.maxHeight * 0.39;

            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppColors.neutral50),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight * 0.62,
                  child: _buildIlustracao(constraints.maxWidth),
                ),
                Positioned(
                  top: alturaCard,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildCard(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIlustracao(double largura) {
    return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.white],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -92,
              right: -58,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),
            Positioned(
              bottom: -78,
              left: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(130),
                ),
              ),
            ),
            Positioned(
              top: 76,
              right: largura * 0.09,
              child: const ExcludeSemantics(
                // TODO: substituir por ilustração customizada quando disponível (asset PNG/SVG).
                child: Icon(
                  Icons.person_rounded,
                  size: 190,
                  color: AppColors.navy,
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 22,
              right: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const IconAvatarBox(
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                      const SizedBox(width: 9),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Conecta',
                              style: AppTextStyles.wordmark.copyWith(
                                color: AppColors.navy,
                              ),
                            ),
                            TextSpan(
                              text: 'Talentos',
                              style: AppTextStyles.wordmark.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mais oportunidades.\nGrandes futuros.',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate(delay: const Duration(milliseconds: 120))
        .fadeIn(duration: const Duration(milliseconds: 650))
        .slideY(
          begin: 0.025,
          end: 0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOut,
        );
  }

  Widget _buildCard() {
    return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.1),
                blurRadius: 22,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: AppTextStyles.bodyText,
                      decoration: _decoracaoCampo(
                        dica: 'E-mail',
                        icone: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      style: AppTextStyles.bodyText,
                      decoration: _decoracaoCampo(
                        dica: 'Senha',
                        icone: Icons.lock_outline_rounded,
                        sufixo: IconButton(
                          tooltip: _senhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: () {
                            setState(() => _senhaVisivel = !_senhaVisivel);
                          },
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _carregando ? 'Entrando...' : 'Entrar',
                      showArrow: true,
                      onPressed: _carregando ? null : _login,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: AppColors.neutral200),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text('ou', style: AppTextStyles.caption),
                        ),
                        const Expanded(
                          child: Divider(color: AppColors.neutral200),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Ainda não tenho uma conta?',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        TextButton(
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CadastroScreen(authService: _authService),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Criar conta',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .slideY(
          begin: 0.06,
          end: 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
  }

  InputDecoration _decoracaoCampo({
    required String dica,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      hintText: dica,
      hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
      prefixIcon: Icon(icone, color: AppColors.neutral600),
      suffixIcon: sufixo,
      filled: true,
      fillColor: AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarErro('Informe seu e-mail e senha para continuar.');
      return;
    }

    if (!_emailValido(email)) {
      _mostrarErro('Informe um e-mail válido.');
      return;
    }

    setState(() => _carregando = true);
    try {
      await _authService.login(email: email, senha: senha);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainNavigationScreen(authService: _authService),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _mostrarErro(error.message);
    } on Exception {
      if (mounted) _mostrarErro('Não foi possível concluir a operação.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  bool _emailValido(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

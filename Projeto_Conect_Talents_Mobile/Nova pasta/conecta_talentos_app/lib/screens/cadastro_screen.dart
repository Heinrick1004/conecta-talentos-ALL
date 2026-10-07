import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';

/// Formulário de criação de conta para novos candidatos.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({this.authService, super.key});

  final AuthService? authService;

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  late final AuthService _authService;
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  bool _carregando = false;
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              left: -76,
              bottom: -84,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 230,
                  height: 230,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.all(Radius.circular(150)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: _conteudo()),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                        children: [
                          const IconAvatarBox(
                            icon: Icons.people_alt_rounded,
                            color: AppColors.primary,
                            size: 54,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Crie sua conta',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displayTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Faça parte da ConectaTalentos e encontre as melhores oportunidades.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                        ],
                      )
                      .animate(delay: const Duration(milliseconds: 100))
                      .fadeIn(duration: const Duration(milliseconds: 500)),
                  const SizedBox(height: 22),
                  AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _campo(
                              controller: _nomeController,
                              dica: 'Nome completo',
                              icone: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              onChanged: _limparErro,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: _emailController,
                              dica: 'E-mail',
                              icone: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: _limparErro,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: _senhaController,
                              dica: 'Senha',
                              icone: Icons.lock_outline_rounded,
                              obscureText: !_senhaVisivel,
                              sufixo: IconButton(
                                tooltip: _senhaVisivel
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: () {
                                  setState(
                                    () => _senhaVisivel = !_senhaVisivel,
                                  );
                                },
                                icon: Icon(
                                  _senhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.neutral600,
                                ),
                              ),
                              onChanged: _limparErro,
                            ),
                            const SizedBox(height: 12),
                            _campo(
                              controller: _confirmarSenhaController,
                              dica: 'Confirmar senha',
                              icone: Icons.lock_outline_rounded,
                              obscureText: !_confirmarSenhaVisivel,
                              textInputAction: TextInputAction.done,
                              sufixo: IconButton(
                                tooltip: _confirmarSenhaVisivel
                                    ? 'Ocultar confirmação de senha'
                                    : 'Mostrar confirmação de senha',
                                onPressed: () {
                                  setState(
                                    () => _confirmarSenhaVisivel =
                                        !_confirmarSenhaVisivel,
                                  );
                                },
                                icon: Icon(
                                  _confirmarSenhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.neutral600,
                                ),
                              ),
                              onChanged: _limparErro,
                            ),
                            if (_erroValidacao != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _erroValidacao!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            PrimaryButton(
                              label: _carregando
                                  ? 'Criando conta...'
                                  : 'Criar conta',
                              showArrow: true,
                              onPressed: _carregando ? null : _validarCadastro,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 20),
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
                          'Já tem uma conta?',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Voltar para o login',
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
        );
      },
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String dica,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? sufixo,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: AppTextStyles.bodyText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: dica,
        hintStyle: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
        prefixIcon: Icon(icone, color: AppColors.neutral600),
        suffixIcon: sufixo,
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  void _limparErro(String _) {
    if (_erroValidacao != null) {
      setState(() => _erroValidacao = null);
    }
  }

  Future<void> _validarCadastro() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarErroValidacao('Preencha todos os campos obrigatórios.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _mostrarErroValidacao('Informe um e-mail válido.');
      return;
    }

    if (senha.length < 8) {
      _mostrarErroValidacao('A senha deve ter pelo menos 8 caracteres.');
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarErroValidacao('As senhas não coincidem.');
      return;
    }

    setState(() {
      _erroValidacao = null;
      _carregando = true;
    });
    try {
      await _authService.registrar(
        nomeCompleto: nome,
        email: email,
        senha: senha,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso! Faça login para continuar.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) _mostrarErroValidacao(error.message);
    } on Exception {
      if (mounted) {
        _mostrarErroValidacao('Não foi possível concluir a operação.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErroValidacao(String mensagem) {
    setState(() => _erroValidacao = mensagem);
  }
}

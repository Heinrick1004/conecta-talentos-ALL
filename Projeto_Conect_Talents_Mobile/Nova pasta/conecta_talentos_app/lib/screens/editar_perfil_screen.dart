import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/perfil_model.dart';
import '../services/api_client.dart';
import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';

/// Edita os campos do perfil disponíveis na API do candidato.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({
    required this.perfil,
    required this.perfilService,
    super.key,
  });

  final PerfilModel perfil;
  final PerfilService perfilService;

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _ufController;
  late final TextEditingController _habilidadesController;
  String? _erro;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final perfil = widget.perfil;
    _nomeController = TextEditingController(text: perfil.nomeCompleto);
    _emailController = TextEditingController(text: perfil.email);
    _telefoneController = TextEditingController(text: perfil.telefone ?? '');
    _cidadeController = TextEditingController(text: perfil.cidade ?? '');
    _ufController = TextEditingController(text: perfil.uf ?? '');
    _habilidadesController = TextEditingController(
      text: perfil.listaHabilidades.join(', '),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _habilidadesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_salvando,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.neutral900,
                    ),
                    const SizedBox(width: 4),
                    Text('Editar perfil', style: AppTextStyles.sectionTitle),
                  ],
                ),
              ),
              Expanded(
                child:
                    SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child:
                                        ValueListenableBuilder<
                                          TextEditingValue
                                        >(
                                          valueListenable: _nomeController,
                                          builder: (context, valor, child) {
                                            final nome = valor.text.trim();
                                            final inicial = nome.isEmpty
                                                ? '?'
                                                : nome.characters.first
                                                      .toUpperCase();
                                            return CircleAvatar(
                                              radius: 48,
                                              backgroundColor:
                                                  AppColors.primary,
                                              child: Text(
                                                inicial,
                                                style: AppTextStyles
                                                    .displayTitle
                                                    .copyWith(
                                                      color: AppColors.white,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  _campo(
                                    key: const Key('perfil-nome'),
                                    controller: _nomeController,
                                    rotulo: 'Nome completo',
                                    icone: Icons.person_outline_rounded,
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 14),
                                  _campo(
                                    key: const Key('perfil-email'),
                                    controller: _emailController,
                                    rotulo: 'E-mail',
                                    icone: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    readOnly: true,
                                    helperText: 'O e-mail da conta não pode ser alterado.',
                                  ),
                                  const SizedBox(height: 14),
                                  _campo(
                                    key: const Key('perfil-telefone'),
                                    controller: _telefoneController,
                                    rotulo: 'Telefone',
                                    icone: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 14),
                                  _campo(
                                    key: const Key('perfil-cidade'),
                                    controller: _cidadeController,
                                    rotulo: 'Cidade',
                                    icone: Icons.location_city_outlined,
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 14),
                                  _campo(
                                    key: const Key('perfil-uf'),
                                    controller: _ufController,
                                    rotulo: 'UF',
                                    icone: Icons.map_outlined,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                  ),
                                  const SizedBox(height: 14),
                                  _campo(
                                    key: const Key('perfil-habilidades'),
                                    controller: _habilidadesController,
                                    rotulo: 'Habilidades',
                                    icone: Icons.stars_outlined,
                                    minLines: 2,
                                    maxLines: 4,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                  if (_erro != null) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      _erro!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  PrimaryButton(
                                    key: const Key('salvar-perfil'),
                                    label: _salvando
                                        ? 'Salvando...'
                                        : 'Salvar alterações',
                                    onPressed: _salvando
                                        ? null
                                        : _salvarAlteracoes,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required Key key,
    required TextEditingController controller,
    required String rotulo,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
    String? helperText,
  }) {
    return TextField(
      key: key,
      controller: controller,
      enabled: !_salvando,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      minLines: minLines,
      maxLines: maxLines,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: AppTextStyles.bodyText,
      onChanged: (_) {
        if (_erro != null) setState(() => _erro = null);
      },
      decoration: InputDecoration(
        labelText: rotulo,
        helperText: helperText,
        helperMaxLines: 2,
        labelStyle: AppTextStyles.bodyText.copyWith(
          color: AppColors.neutral600,
        ),
        prefixIcon: Icon(icone, color: AppColors.neutral600),
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

  Future<void> _salvarAlteracoes() async {
    if (_salvando) return;
    FocusScope.of(context).unfocus();
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    final cidade = _cidadeController.text.trim();
    final uf = _ufController.text.trim();
    String? erro;
    if (nome.isEmpty) {
      erro = 'O nome completo é obrigatório.';
    } else if (nome.length > 150) {
      erro = 'O nome completo deve ter no máximo 150 caracteres.';
    } else if (telefone.length > 30) {
      erro = 'O telefone deve ter no máximo 30 caracteres.';
    } else if (cidade.length > 100) {
      erro = 'A cidade deve ter no máximo 100 caracteres.';
    } else if (uf.isNotEmpty && !RegExp(r'^[A-Za-z]{2}$').hasMatch(uf)) {
      erro = 'Informe uma UF com duas letras.';
    }
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final perfilAtualizado = await widget.perfilService.atualizarPerfil(
        nomeCompleto: _nomeController.text,
        telefone: _telefoneController.text,
        cidade: _cidadeController.text,
        uf: _ufController.text,
        habilidades: _habilidadesController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop<PerfilModel>(perfilAtualizado);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = error.message;
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Não foi possível atualizar seu perfil. Tente novamente.';
      });
    }
  }
}

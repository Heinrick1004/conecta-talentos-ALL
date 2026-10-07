import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_usuario.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';

/// Formulário para editar os dados locais do candidato.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

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
  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: mockUsuario.nome);
    _emailController = TextEditingController(text: mockUsuario.email);
    _telefoneController = TextEditingController(text: mockUsuario.telefone);
    _cidadeController = TextEditingController(text: mockUsuario.cidade);
    _ufController = TextEditingController(text: mockUsuario.uf);
    _habilidadesController = TextEditingController(
      text: mockUsuario.habilidades.join(', '),
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.pop(context),
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
                                  child: AnimatedBuilder(
                                    animation: mockUsuario,
                                    builder: (context, child) {
                                      final inicial =
                                          mockUsuario.nome.trim().isEmpty
                                          ? '?'
                                          : mockUsuario.nome
                                                .trim()
                                                .characters
                                                .first
                                                .toUpperCase();

                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 48,
                                            backgroundColor: AppColors.primary,
                                            child: Text(
                                              inicial,
                                              style: AppTextStyles.displayTitle
                                                  .copyWith(
                                                    color: AppColors.white,
                                                  ),
                                            ),
                                          ),
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Material(
                                              color: AppColors.navy,
                                              shape: const CircleBorder(),
                                              child: IconButton(
                                                tooltip: 'Alterar foto',
                                                onPressed: () {
                                                  // TODO: permitir upload de foto no futuro.
                                                },
                                                icon: const Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 17,
                                                  color: AppColors.white,
                                                ),
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 34,
                                                      height: 34,
                                                    ),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _campo(
                                  controller: _nomeController,
                                  rotulo: 'Nome completo',
                                  icone: Icons.person_outline_rounded,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  controller: _emailController,
                                  rotulo: 'E-mail',
                                  icone: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  controller: _telefoneController,
                                  rotulo: 'Telefone',
                                  icone: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  controller: _cidadeController,
                                  rotulo: 'Cidade',
                                  icone: Icons.location_city_outlined,
                                  textCapitalization: TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  controller: _ufController,
                                  rotulo: 'UF',
                                  icone: Icons.map_outlined,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 2,
                                ),
                                const SizedBox(height: 14),
                                _campo(
                                  controller: _habilidadesController,
                                  rotulo: 'Habilidades',
                                  icone: Icons.stars_outlined,
                                  minLines: 2,
                                  maxLines: 4,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                                if (_erroValidacao != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _erroValidacao!,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                PrimaryButton(
                                  label: 'Salvar alterações',
                                  onPressed: _salvarAlteracoes,
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
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String rotulo,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      autocorrect: keyboardType != TextInputType.emailAddress,
      style: AppTextStyles.bodyText,
      onChanged: (_) {
        if (_erroValidacao != null) {
          setState(() => _erroValidacao = null);
        }
      },
      decoration: InputDecoration(
        labelText: rotulo,
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

  void _salvarAlteracoes() {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    if (nome.isEmpty || email.isEmpty) {
      setState(() => _erroValidacao = 'Nome e e-mail são obrigatórios.');
      return;
    }

    final habilidades = _habilidadesController.text
        .split(RegExp(r'[,;\n]'))
        .map((habilidade) => habilidade.trim())
        .where((habilidade) => habilidade.isNotEmpty)
        .toList();

    mockUsuario.atualizar(
      nome: nome,
      email: email,
      telefone: _telefoneController.text.trim(),
      cidade: _cidadeController.text.trim(),
      uf: _ufController.text.trim().toUpperCase(),
      habilidades: habilidades,
    );

    // TODO: ao integrar com a API, trocar a atualização em memória por uma chamada PUT /api/candidato/perfil.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Perfil atualizado!')));
  }
}

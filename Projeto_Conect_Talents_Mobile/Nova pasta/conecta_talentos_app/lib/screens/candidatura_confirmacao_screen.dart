import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_usuario.dart';
import '../mock/mock_vagas.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'editar_perfil_screen.dart';

/// Confirma uma candidatura usando os dados já registrados no perfil.
class CandidaturaConfirmacaoScreen extends StatefulWidget {
  const CandidaturaConfirmacaoScreen({
    required this.vaga,
    this.onNavigationItemSelected,
    super.key,
  });

  final VagaMock vaga;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<CandidaturaConfirmacaoScreen> createState() =>
      _CandidaturaConfirmacaoScreenState();
}

class _CandidaturaConfirmacaoScreenState
    extends State<CandidaturaConfirmacaoScreen> {
  final _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corDestaque =
        AppColors.cardAccentColors[widget.vaga.indiceDestaque %
            AppColors.cardAccentColors.length];

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
                  Expanded(
                    child: Text(
                      'Revisar candidatura',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          IconAvatarBox.initials(
                            label: widget.vaga.sigla,
                            color: corDestaque,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vaga.titulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.vaga.empresa,
                                  style: AppTextStyles.cardSubtitle,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.vaga.local,
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seus dados',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const EditarPerfilScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Editar perfil',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                          animation: mockUsuario,
                          builder: (context, child) {
                            return AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LinhaDado(
                                    icone: Icons.person_outline_rounded,
                                    rotulo: 'Nome completo',
                                    valor: mockUsuario.nome,
                                  ),
                                  const Divider(height: 22),
                                  _LinhaDado(
                                    icone: Icons.mail_outline_rounded,
                                    rotulo: 'E-mail',
                                    valor: mockUsuario.email,
                                  ),
                                  const Divider(height: 22),
                                  _LinhaDado(
                                    icone: Icons.phone_outlined,
                                    rotulo: 'Telefone',
                                    valor: mockUsuario.telefone,
                                  ),
                                  const Divider(height: 22),
                                  _LinhaDado(
                                    icone: Icons.location_on_outlined,
                                    rotulo: 'Cidade/UF',
                                    valor:
                                        '${mockUsuario.cidade}, ${mockUsuario.uf}',
                                  ),
                                  const Divider(height: 22),
                                  Text(
                                    'Habilidades',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.neutral600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final habilidade
                                          in mockUsuario.habilidades)
                                        StatusBadge(
                                          text: habilidade,
                                          type: StatusBadgeType.neutral,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 450))
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1, 1),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'Mensagem para a empresa',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mensagemController,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.bodyText,
                      decoration: InputDecoration(
                        hintText: 'Conte brevemente por que você é um bom candidato (opcional)',
                        hintStyle: AppTextStyles.bodyText.copyWith(
                          color: AppColors.neutral600,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.neutral200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.neutral200,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: const Border(top: BorderSide(color: AppColors.neutral200)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: PrimaryButton(
            label: 'Confirmar candidatura',
            showArrow: true,
            onPressed: _confirmarCandidatura,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCandidatura() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon:
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ).animate().fadeIn().scale(
                begin: const Offset(0.55, 0.55),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
          title: Text(
            'Candidatura enviada!',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          content: Text(
            'Sua candidatura para ${widget.vaga.titulo} foi confirmada.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.neutral600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Ir para candidaturas',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    // TODO: registrar a candidatura na lista real quando a API estiver integrada.
    widget.onNavigationItemSelected?.call(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _LinhaDado extends StatelessWidget {
  const _LinhaDado({
    required this.icone,
    required this.rotulo,
    required this.valor,
  });

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 19, color: AppColors.neutral600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rotulo,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 2),
              Text(valor, style: AppTextStyles.bodyText),
            ],
          ),
        ),
      ],
    );
  }
}

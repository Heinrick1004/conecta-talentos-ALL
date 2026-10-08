import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../mock/mock_vagas.dart';
import '../services/api_client.dart';
import '../services/candidaturas_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/icon_avatar_box.dart';
import '../widgets/primary_button.dart';

/// Vincula a conta autenticada do candidato à vaga selecionada.
class CandidaturaConfirmacaoScreen extends StatefulWidget {
  const CandidaturaConfirmacaoScreen({
    required this.vaga,
    required this.candidaturasService,
    this.onNavigationItemSelected,
    super.key,
  });

  final VagaMock vaga;
  final CandidaturasService candidaturasService;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<CandidaturaConfirmacaoScreen> createState() =>
      _CandidaturaConfirmacaoScreenState();
}

class _CandidaturaConfirmacaoScreenState
    extends State<CandidaturaConfirmacaoScreen> {
  bool _enviando = false;
  bool _candidaturaResolvida = false;

  bool get _bloqueado => _enviando || _candidaturaResolvida;

  @override
  Widget build(BuildContext context) {
    final corDestaque =
        AppColors.cardAccentColors[widget.vaga.indiceDestaque %
            AppColors.cardAccentColors.length];

    return PopScope(
      canPop: !_bloqueado,
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
                      onPressed: _bloqueado
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.neutral900,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Confirmar candidatura',
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
                      Text(
                        'Ao confirmar, sua conta de candidato será vinculada a esta vaga.',
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Você poderá acompanhar o andamento em Minhas candidaturas.',
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                      if (_enviando) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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
              border: const Border(
                top: BorderSide(color: AppColors.neutral200),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: PrimaryButton(
              key: const Key('confirmar-candidatura'),
              label: _enviando
                  ? 'Enviando candidatura...'
                  : 'Confirmar candidatura',
              showArrow: !_enviando,
              onPressed: _bloqueado ? null : _confirmarCandidatura,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCandidatura() async {
    if (_bloqueado) return;
    final vagaId = widget.vaga.id;
    if (vagaId == null) {
      _mostrarErro(
        'Não foi possível identificar esta vaga. Abra uma vaga novamente.',
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await widget.candidaturasService.criarCandidatura(vagaId);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() {
          _enviando = false;
          _candidaturaResolvida = true;
        });
        await _mostrarDuplicidade(error.message);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        setState(() => _enviando = false);
        _mostrarErro(error.message);
      }
      return;
    } on Exception catch (error) {
      debugPrint('Falha ao enviar candidatura: $error');
      if (!mounted) return;
      setState(() => _enviando = false);
      _mostrarErro('Não foi possível enviar sua candidatura. Tente novamente.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _enviando = false;
      _candidaturaResolvida = true;
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
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
        ),
      ),
    );

    if (!mounted) return;
    widget.onNavigationItemSelected?.call(1);
    Navigator.of(context).pop(true);
  }

  Future<void> _mostrarDuplicidade(String mensagem) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Você já se candidatou'),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Voltar à vaga'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

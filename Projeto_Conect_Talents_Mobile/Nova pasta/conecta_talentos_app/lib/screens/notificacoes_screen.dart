import 'package:flutter/material.dart';

import '../models/notificacao_model.dart';
import '../services/api_client.dart';
import '../services/notificacoes_service.dart';
import '../services/perfil_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';

/// Caixa de entrada das atualizações reais das candidaturas.
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({
    required this.notificacoesService,
    required this.perfilService,
    this.onNavigationItemSelected,
    super.key,
  });

  final NotificacoesService notificacoesService;
  final PerfilService perfilService;
  final ValueChanged<int>? onNavigationItemSelected;

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  @override
  void initState() {
    super.initState();
    // O serviço também atualiza os headers da rota anterior. Aguarda o frame
    // para não notificar widgets enquanto o Navigator constrói esta rota.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarNotificacoes();
    });
  }

  Future<void> _carregarNotificacoes() async {
    try {
      await widget.notificacoesService.carregarNotificacoes(forceRefresh: true);
    } on ApiException {
      // O serviço preserva a lista e expõe o erro para permitir tentar novamente.
    }
  }

  Future<void> _marcarComoLida(int id) async {
    try {
      await widget.notificacoesService.marcarComoLida(id);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _verCandidaturas() {
    Navigator.of(context).pop();
    widget.onNavigationItemSelected?.call(1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notificacoesService,
      builder: (context, _) {
        final service = widget.notificacoesService;
        return Scaffold(
          backgroundColor: AppColors.neutral50,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Notificações',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _carregarNotificacoes,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        if (service.naoLidas > 0) ...[
                          Text(
                            service.naoLidas == 1
                                ? '1 não lida'
                                : '${service.naoLidas} não lidas',
                            style: AppTextStyles.bodyText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (service.carregando && service.notificacoes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else ...[
                          if (service.erro != null)
                            AppCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 36,
                                    color: AppColors.danger,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    service.erro!,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyText,
                                  ),
                                  TextButton(
                                    onPressed: service.carregando
                                        ? null
                                        : _carregarNotificacoes,
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            )
                          else if (service.notificacoes.isEmpty)
                            AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    color: AppColors.primary,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Você não possui notificações.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'As atualizações das suas candidaturas aparecerão aqui.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyText.copyWith(
                                      color: AppColors.neutral600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          for (final notificacao in service.notificacoes)
                            _NotificacaoCard(
                              notificacao: notificacao,
                              marcando: service.estaMarcandoComoLida(
                                notificacao.id,
                              ),
                              onMarcar: () => _marcarComoLida(notificacao.id),
                              onVerCandidaturas:
                                  widget.onNavigationItemSelected == null
                                  ? null
                                  : _verCandidaturas,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificacaoCard extends StatelessWidget {
  const _NotificacaoCard({
    required this.notificacao,
    required this.marcando,
    required this.onMarcar,
    this.onVerCandidaturas,
  });

  final NotificacaoModel notificacao;
  final bool marcando;
  final VoidCallback onMarcar;
  final VoidCallback? onVerCandidaturas;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('notificacao-${notificacao.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      gradient: notificacao.lida
          ? null
          : const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.white],
            ),
      child: InkWell(
        key: ValueKey('marcar-notificacao-${notificacao.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: notificacao.lida || marcando ? null : onMarcar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notificacao.titulo,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontWeight: notificacao.lida
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (marcando)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else if (!notificacao.lida)
                  Semantics(
                    label: 'Não lida',
                    child: Icon(
                      Icons.circle,
                      key: ValueKey('notificacao-nao-lida-${notificacao.id}'),
                      color: AppColors.primary,
                      size: 10,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(notificacao.mensagem, style: AppTextStyles.bodyText),
            const SizedBox(height: 12),
            Text(notificacao.dataFormatada, style: AppTextStyles.caption),
            if (onVerCandidaturas != null)
              TextButton(
                onPressed: onVerCandidaturas,
                child: const Text('Ver candidaturas'),
              ),
          ],
        ),
      ),
    );
  }
}

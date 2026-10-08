import 'package:flutter/material.dart';

import '../models/candidatura_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CandidaturaProgress extends StatelessWidget {
  const CandidaturaProgress({required this.candidatura, super.key});

  final CandidaturaModel candidatura;

  Color get _corProgresso => switch (candidatura.status) {
    CandidaturaStatus.emAnalise => AppColors.primary,
    CandidaturaStatus.selecionado => AppColors.success,
    CandidaturaStatus.rejeitado => AppColors.neutral400,
  };

  bool get _rejeitado => candidatura.status == CandidaturaStatus.rejeitado;
  bool get _selecionado => candidatura.status == CandidaturaStatus.selecionado;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < candidatura.etapas.length; index++) ...[
              if (index > 0)
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(height: 2, color: AppColors.neutral200),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            _selecionado || index <= candidatura.etapaAtual
                            ? 1
                            : 0,
                        child: Container(height: 2, color: _corProgresso),
                      ),
                    ],
                  ),
                ),
              _PontoProgresso(
                ativo: _selecionado || index <= candidatura.etapaAtual,
                cor: _rejeitado ? AppColors.neutral400 : _corProgresso,
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var index = 0; index < candidatura.etapas.length; index++)
              Expanded(
                child: Text(
                  candidatura.etapas[index],
                  textAlign: index == 0
                      ? TextAlign.left
                      : index == candidatura.etapas.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        !_rejeitado &&
                            (_selecionado || index <= candidatura.etapaAtual)
                        ? _corProgresso
                        : AppColors.neutral600,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PontoProgresso extends StatelessWidget {
  const _PontoProgresso({required this.ativo, required this.cor});

  final bool ativo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: ativo ? cor : AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: ativo ? cor : AppColors.neutral200, width: 2),
      ),
    );
  }
}

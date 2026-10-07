import 'package:flutter/material.dart';

/// Dados locais dos treinamentos exibidos na tela de capacitação.
class TreinamentoMock {
  const TreinamentoMock({
    required this.titulo,
    required this.descricao,
    required this.progressoPercentual,
    required this.modulos,
    required this.icone,
  });

  final String titulo;
  final String descricao;
  final int progressoPercentual;
  final int modulos;
  final IconData icone;
}

const mockCapacitacoes = <TreinamentoMock>[
  TreinamentoMock(
    titulo: 'Diversidade e Inclusão no Ambiente de Trabalho',
    descricao: 'Entenda a importância da diversidade e como promover um ambiente mais acolhedor e respeitoso.',
    progressoPercentual: 75,
    modulos: 4,
    icone: Icons.groups_rounded,
  ),
  TreinamentoMock(
    titulo: 'Relações Étnico-Raciais e Afrodescendência',
    descricao: 'Conheça a história e a cultura afro-brasileira e a importância do combate ao racismo.',
    progressoPercentual: 0,
    modulos: 3,
    icone: Icons.spa_rounded,
  ),
  TreinamentoMock(
    titulo: 'Empreendedorismo em TI',
    descricao: 'Desenvolva o pensamento estratégico e descubra novas oportunidades no mercado.',
    progressoPercentual: 20,
    modulos: 5,
    icone: Icons.lightbulb_rounded,
  ),
];

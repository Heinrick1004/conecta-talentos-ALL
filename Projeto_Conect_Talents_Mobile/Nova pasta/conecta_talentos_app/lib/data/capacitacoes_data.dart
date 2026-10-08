import 'package:flutter/material.dart';

/// Conteúdo estático do módulo conceitual de capacitação.
class CapacitacaoItem {
  const CapacitacaoItem({
    required this.titulo,
    required this.descricao,
    required this.modulos,
    required this.icone,
  });

  final String titulo;
  final String descricao;
  final int modulos;
  final IconData icone;
}

const capacitacoesData = <CapacitacaoItem>[
  CapacitacaoItem(
    titulo: 'Diversidade e Inclusão no Ambiente de Trabalho',
    descricao: 'Entenda a importância da diversidade e como promover um ambiente mais acolhedor e respeitoso.',
    modulos: 4,
    icone: Icons.groups_rounded,
  ),
  CapacitacaoItem(
    titulo: 'Relações Étnico-Raciais e Afrodescendência',
    descricao: 'Conheça a história e a cultura afro-brasileira e a importância do combate ao racismo.',
    modulos: 3,
    icone: Icons.spa_rounded,
  ),
  CapacitacaoItem(
    titulo: 'Empreendedorismo em TI',
    descricao: 'Desenvolva o pensamento estratégico e descubra novas oportunidades no mercado.',
    modulos: 5,
    icone: Icons.lightbulb_rounded,
  ),
];

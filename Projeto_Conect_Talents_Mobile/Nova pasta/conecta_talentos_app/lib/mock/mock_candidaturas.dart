import 'package:flutter/material.dart';

import 'mock_vagas.dart';

enum CandidaturaStatus { emAnalise, selecionado, rejeitado }

/// Modelo e exemplos locais usados pela tela de candidaturas.
class CandidaturaMock {
  const CandidaturaMock({
    required this.vaga,
    required this.status,
    required this.etapas,
    required this.etapaAtual,
    required this.icone,
  });

  final VagaMock vaga;
  final CandidaturaStatus status;
  final List<String> etapas;
  final int etapaAtual;
  final IconData icone;

  String get titulo => vaga.titulo;
  String get empresa => vaga.empresa;
  String get local => vaga.local;
  String get modalidade => vaga.modalidade;

  String get textoStatus => switch (status) {
    CandidaturaStatus.emAnalise => 'Em análise',
    CandidaturaStatus.selecionado => 'Selecionado',
    CandidaturaStatus.rejeitado => 'Rejeitado',
  };
}

const mockCandidaturas = <CandidaturaMock>[
  CandidaturaMock(
    vaga: mockVagaDesenvolvedor,
    status: CandidaturaStatus.emAnalise,
    etapas: ['Candidatura', 'Entrevista', 'Resultado'],
    etapaAtual: 0,
    icone: Icons.code_rounded,
  ),
  CandidaturaMock(
    vaga: mockVagaAnalista,
    status: CandidaturaStatus.selecionado,
    etapas: ['Candidatura', 'Entrevista', 'Proposta'],
    etapaAtual: 2,
    icone: Icons.bar_chart_rounded,
  ),
  CandidaturaMock(
    vaga: mockVagaEstagio,
    status: CandidaturaStatus.emAnalise,
    etapas: ['Candidatura', 'Entrevista', 'Resultado'],
    etapaAtual: 0,
    icone: Icons.laptop_mac_rounded,
  ),
  CandidaturaMock(
    vaga: VagaMock(
      titulo: 'Técnico de Suporte',
      empresa: 'HelpTech',
      local: 'Sorocaba, SP',
      modalidade: 'Presencial',
      sigla: 'HT',
      iconeModalidade: Icons.business_outlined,
      indiceDestaque: 3,
    ),
    status: CandidaturaStatus.rejeitado,
    etapas: ['Candidatura', 'Entrevista', 'Resultado'],
    etapaAtual: 0,
    icone: Icons.support_agent_rounded,
  ),
];

import 'package:flutter/material.dart';

/// Dados de apresentação de uma vaga enquanto a integração com a API não existe.
class VagaMock {
  const VagaMock({
    required this.titulo,
    required this.empresa,
    required this.local,
    required this.modalidade,
    required this.sigla,
    required this.iconeModalidade,
    this.descricao = '',
    this.requisitos = const [],
    required this.indiceDestaque,
  });

  final String titulo;
  final String empresa;
  final String local;
  final String modalidade;
  final String sigla;
  final IconData iconeModalidade;
  final String descricao;
  final List<String> requisitos;
  final int indiceDestaque;
}

const mockVagaDesenvolvedor = VagaMock(
  titulo: 'Desenvolvedor .NET',
  empresa: 'XP Tecnologia',
  local: 'Sorocaba, SP',
  modalidade: 'Híbrido',
  sigla: 'XP',
  iconeModalidade: Icons.swap_horiz_rounded,
  descricao:
      'Você fará parte de um time que desenvolve e mantém aplicações '
      'financeiras escaláveis. A rotina inclui colaborar com produto e '
      'design, propor melhorias técnicas e garantir a qualidade das entregas.',
  requisitos: [
    'Experiência com desenvolvimento em C# e .NET.',
    'Conhecimento em APIs REST e integração entre serviços.',
    'Familiaridade com bancos de dados relacionais e SQL.',
    'Prática com Git, testes automatizados e trabalho em equipe.',
  ],
  indiceDestaque: 0,
);

const mockVagaAnalista = VagaMock(
  titulo: 'Analista de Sistemas',
  empresa: 'TechSolutions',
  local: 'São Paulo, SP',
  modalidade: 'Remoto',
  sigla: 'TS',
  iconeModalidade: Icons.home_outlined,
  descricao:
      'A pessoa selecionada vai entender as necessidades das áreas de negócio '
      'e traduzi-las em soluções de sistemas. Também apoiará integrações, '
      'documentação e evolução contínua das plataformas da empresa.',
  requisitos: [
    'Ensino superior cursando ou completo em Sistemas de Informação ou áreas afins.',
    'Experiência com levantamento e documentação de requisitos.',
    'Conhecimento em modelagem de processos e consultas SQL.',
    'Boa comunicação para atuar junto a equipes técnicas e de negócio.',
  ],
  indiceDestaque: 1,
);

const mockVagaEstagio = VagaMock(
  titulo: 'Estágio em TI',
  empresa: 'Next Tecnologia',
  local: 'Campinas, SP',
  modalidade: 'Presencial',
  sigla: 'NT',
  iconeModalidade: Icons.business_outlined,
  descricao:
      'Uma oportunidade para aprender na prática e apoiar a equipe de '
      'tecnologia em projetos internos. Você terá acompanhamento de pessoas '
      'experientes e contato com suporte, infraestrutura e desenvolvimento.',
  requisitos: [
    'Estar cursando graduação ou curso técnico na área de TI.',
    'Ter interesse em aprender sobre tecnologia e solucionar problemas.',
    'Conhecimentos básicos de informática e lógica de programação.',
    'Disponibilidade para estagiar presencialmente em Campinas.',
  ],
  indiceDestaque: 2,
);

const mockVagas = <VagaMock>[
  mockVagaDesenvolvedor,
  mockVagaAnalista,
  mockVagaEstagio,
];

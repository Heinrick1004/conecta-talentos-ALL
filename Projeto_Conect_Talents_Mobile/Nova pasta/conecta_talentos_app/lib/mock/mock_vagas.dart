import 'package:flutter/material.dart';

/// Modelo de apresentação compartilhado por vagas reais e mockadas.
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
    this.id,
    this.dataInicio,
    this.dataFim,
    this.jaCandidatado = false,
    this.favoritada = false,
  });

  factory VagaMock.fromJson(Map<String, dynamic> json) {
    final id = _intValue(json['id']);
    final cidade = _stringValue(json['cidade']);
    final uf = _stringValue(json['uf']);
    final modalidadeOriginal = _stringValue(json['modalidade']);
    final modalidadeNormalizada = modalidadeOriginal.toLowerCase();
    final modalidade = modalidadeNormalizada == 'hibrido'
        ? 'Híbrido'
        : modalidadeOriginal;
    final empresa = _stringValue(json['nomeFantasiaEmpresa']);

    return VagaMock(
      id: id,
      titulo: _stringValue(json['titulo']),
      empresa: empresa,
      local: [cidade, uf].where((parte) => parte.isNotEmpty).join(', '),
      modalidade: modalidade,
      sigla: _siglaEmpresa(empresa),
      iconeModalidade: switch (modalidadeNormalizada) {
        'remoto' => Icons.home_outlined,
        'presencial' => Icons.business_outlined,
        'hibrido' => Icons.swap_horiz_rounded,
        _ => Icons.work_outline_rounded,
      },
      descricao: _stringValue(json['descricao']),
      requisitos: _requisitos(json['requisitos']),
      indiceDestaque: id ?? 0,
      dataInicio: _dateValue(json['dataInicio']),
      dataFim: _dateValue(json['dataFim']),
      jaCandidatado: json['jaCandidatado'] == true,
      favoritada: json['favoritada'] == true,
    );
  }

  final int? id;
  final String titulo;
  final String empresa;
  final String local;
  final String modalidade;
  final String sigla;
  final IconData iconeModalidade;
  final String descricao;
  final List<String> requisitos;
  final int indiceDestaque;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool jaCandidatado;
  final bool favoritada;

  static String _stringValue(Object? value) =>
      value is String ? value.trim() : '';

  static int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static List<String> _requisitos(Object? value) {
    if (value is! String) return const [];
    return value
        .split(RegExp(r'[;\r\n]+'))
        .map((requisito) => requisito.trim())
        .where((requisito) => requisito.isNotEmpty)
        .toList(growable: false);
  }

  static String _siglaEmpresa(String empresa) {
    final palavras = empresa
        .split(RegExp(r'\s+'))
        .where((palavra) => palavra.isNotEmpty)
        .toList(growable: false);
    if (palavras.isEmpty) return '';
    if (palavras.length == 1) {
      final palavra = palavras.first;
      return palavra.substring(0, palavra.length < 2 ? 1 : 2).toUpperCase();
    }
    return palavras
        .take(2)
        .map((palavra) => palavra.substring(0, 1).toUpperCase())
        .join();
  }
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

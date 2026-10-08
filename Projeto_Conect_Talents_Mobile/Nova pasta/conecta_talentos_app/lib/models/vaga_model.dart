import 'package:flutter/material.dart';

/// Modelo de apresentação das vagas recebidas da API.
class VagaModel {
  const VagaModel({
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

  factory VagaModel.fromJson(Map<String, dynamic> json) {
    final id = _intValue(json['id']);
    final cidade = _stringValue(json['cidade']);
    final uf = _stringValue(json['uf']);
    final modalidadeOriginal = _stringValue(json['modalidade']);
    final modalidadeNormalizada = modalidadeOriginal.toLowerCase();
    final modalidade = modalidadeNormalizada == 'hibrido'
        ? 'Híbrido'
        : modalidadeOriginal;
    final empresa = _stringValue(json['nomeFantasiaEmpresa']);

    return VagaModel(
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

  VagaModel copyWith({bool? jaCandidatado, bool? favoritada}) {
    return VagaModel(
      id: id,
      titulo: titulo,
      empresa: empresa,
      local: local,
      modalidade: modalidade,
      sigla: sigla,
      iconeModalidade: iconeModalidade,
      descricao: descricao,
      requisitos: requisitos,
      indiceDestaque: indiceDestaque,
      dataInicio: dataInicio,
      dataFim: dataFim,
      jaCandidatado: jaCandidatado ?? this.jaCandidatado,
      favoritada: favoritada ?? this.favoritada,
    );
  }

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

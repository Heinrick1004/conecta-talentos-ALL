import 'package:flutter/material.dart';

import '../models/vaga_model.dart';
import '../services/api_client.dart';

enum CandidaturaStatus { emAnalise, selecionado, rejeitado }

class CandidaturaModel {
  const CandidaturaModel({
    required this.id,
    required this.status,
    required this.dataCandidatura,
    required this.atualizadoEm,
    required this.vaga,
  });

  factory CandidaturaModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final vagaJson = json['vaga'];
    if (id is! int || id <= 0 || vagaJson is! Map<String, dynamic>) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final vagaId = vagaJson['id'];
    if (vagaId is! int || vagaId <= 0) {
      throw const ApiException('Resposta inválida do servidor.');
    }

    return CandidaturaModel(
      id: id,
      status: _status(json['status']),
      dataCandidatura: _data(json['dataCandidatura']),
      atualizadoEm: _data(json['atualizadoEm']),
      vaga: VagaModel.fromJson(vagaJson).copyWith(jaCandidatado: true),
    );
  }

  final int id;
  final CandidaturaStatus status;
  final DateTime dataCandidatura;
  final DateTime atualizadoEm;
  final VagaModel vaga;

  String get titulo => vaga.titulo;
  String get empresa => vaga.empresa;
  String get local => vaga.local;
  String get modalidade => vaga.modalidade;
  IconData get icone => vaga.iconeModalidade;

  String get textoStatus => switch (status) {
    CandidaturaStatus.emAnalise => 'Em análise',
    CandidaturaStatus.selecionado => 'Selecionado',
    CandidaturaStatus.rejeitado => 'Rejeitado',
  };

  List<String> get etapas => [
    'Candidatura',
    'Em análise',
    status == CandidaturaStatus.selecionado ? 'Selecionado' : 'Resultado',
  ];

  int get etapaAtual => status == CandidaturaStatus.emAnalise ? 1 : 2;

  static CandidaturaStatus _status(Object? value) {
    switch (value) {
      case 'Pendente':
        return CandidaturaStatus.emAnalise;
      case 'Aceita':
        return CandidaturaStatus.selecionado;
      case 'Recusada':
        return CandidaturaStatus.rejeitado;
      default:
        debugPrint('Status de candidatura desconhecido: $value.');
        return CandidaturaStatus.emAnalise;
    }
  }

  static DateTime _data(Object? value) {
    if (value is! String) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final partes = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    final data = DateTime.tryParse(value);
    if (partes == null || data == null) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final ano = int.parse(partes.group(1)!);
    final mes = int.parse(partes.group(2)!);
    final dia = int.parse(partes.group(3)!);
    final calendario = DateTime(ano, mes, dia);
    if (calendario.year != ano ||
        calendario.month != mes ||
        calendario.day != dia) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return data;
  }
}

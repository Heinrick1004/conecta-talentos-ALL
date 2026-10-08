import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';

void main() {
  test('converte dados da API e constrói a vaga resumida real', () {
    final candidatura = CandidaturaModel.fromJson(_json());

    expect(candidatura.id, 10);
    expect(candidatura.vaga.id, 7);
    expect(candidatura.titulo, 'Desenvolvedor .NET');
    expect(candidatura.empresa, 'Empresa X');
    expect(candidatura.local, 'Sorocaba, SP');
    expect(candidatura.modalidade, 'Híbrido');
    expect(candidatura.vaga.sigla, 'EX');
    expect(candidatura.icone, Icons.swap_horiz_rounded);
    expect(candidatura.vaga.indiceDestaque, 7);
    expect(candidatura.vaga.descricao, isEmpty);
    expect(candidatura.vaga.requisitos, isEmpty);
    expect(candidatura.vaga.jaCandidatado, isTrue);
  });

  test('mantém as datas sem fuso retornadas pelo backend', () {
    final candidatura = CandidaturaModel.fromJson(_json());

    expect(candidatura.dataCandidatura, DateTime(2026, 10, 7, 23, 30));
    expect(candidatura.atualizadoEm, DateTime(2026, 10, 8, 9, 15));
    expect(candidatura.dataCandidatura.isUtc, isFalse);
  });

  for (final (valor, status, texto, etapa, resultado) in [
    ('Pendente', CandidaturaStatus.emAnalise, 'Em análise', 1, 'Resultado'),
    ('Aceita', CandidaturaStatus.selecionado, 'Selecionado', 2, 'Selecionado'),
    ('Recusada', CandidaturaStatus.rejeitado, 'Rejeitado', 2, 'Resultado'),
  ]) {
    test('apresenta status $valor com progresso compatível com a API', () {
      final candidatura = CandidaturaModel.fromJson(
        _json()..['status'] = valor,
      );

      expect(candidatura.status, status);
      expect(candidatura.textoStatus, texto);
      expect(candidatura.etapaAtual, etapa);
      expect(candidatura.etapas, ['Candidatura', 'Em análise', resultado]);
    });
  }

  test('status desconhecido utiliza o fallback Em análise', () {
    final candidatura = CandidaturaModel.fromJson(
      _json()..['status'] = 'Status futuro',
    );

    expect(candidatura.status, CandidaturaStatus.emAnalise);
    expect(candidatura.textoStatus, 'Em análise');
  });

  for (final (campo, valor) in <(String, Object?)>[
    ('id', null),
    ('id', 0),
    ('vaga', null),
    ('vaga', {'id': 0}),
    ('dataCandidatura', 'data inválida'),
    ('dataCandidatura', '2026-02-30T12:00:00'),
    ('atualizadoEm', null),
  ]) {
    test('resposta inválida em $campo=$valor gera erro controlado', () {
      expect(
        () => CandidaturaModel.fromJson(_json()..[campo] = valor),
        throwsA(isA<ApiException>()),
      );
    });
  }
}

Map<String, dynamic> _json() => {
  'id': 10,
  'status': 'Pendente',
  'dataCandidatura': '2026-10-07T23:30:00',
  'atualizadoEm': '2026-10-08T09:15:00',
  'vaga': {
    'id': 7,
    'titulo': 'Desenvolvedor .NET',
    'nomeFantasiaEmpresa': 'Empresa X',
    'cidade': 'Sorocaba',
    'uf': 'SP',
    'modalidade': 'Hibrido',
  },
};

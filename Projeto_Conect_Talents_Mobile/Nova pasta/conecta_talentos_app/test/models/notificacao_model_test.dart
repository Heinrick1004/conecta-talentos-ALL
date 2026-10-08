import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/models/notificacao_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';

void main() {
  test('converte os seis campos reais retornados pela API', () {
    final notificacao = NotificacaoModel.fromJson(_json());

    expect(notificacao.id, 15);
    expect(notificacao.titulo, 'Sua candidatura foi aceita');
    expect(
      notificacao.mensagem,
      'A candidatura para a vaga "Desenvolvedor .NET" foi aceita.',
    );
    expect(notificacao.lida, isFalse);
    expect(notificacao.criadoEm, DateTime(2026, 10, 7, 20, 30));
    expect(notificacao.criadoEm.isUtc, isFalse);
    expect(notificacao.candidaturaId, 110);
    expect(notificacao.dataFormatada, '07/10/2026 às 20:30');
  });

  test('aceita notificação já lida', () {
    expect(NotificacaoModel.fromJson(_json()..['lida'] = true).lida, isTrue);
  });

  test('normaliza apenas os espaços externos de título e mensagem', () {
    final notificacao = NotificacaoModel.fromJson(
      _json()
        ..['titulo'] = '  Candidatura aceita  '
        ..['mensagem'] = '  Sua candidatura foi aceita.  ',
    );

    expect(notificacao.titulo, 'Candidatura aceita');
    expect(notificacao.mensagem, 'Sua candidatura foi aceita.');
  });

  test('copyWith altera a leitura sem mudar o item original ou seus dados', () {
    final original = NotificacaoModel.fromJson(_json());
    final lida = original.copyWith(lida: true);

    expect(original.lida, isFalse);
    expect(lida.lida, isTrue);
    expect(lida.id, original.id);
    expect(lida.titulo, original.titulo);
    expect(lida.mensagem, original.mensagem);
    expect(lida.criadoEm, original.criadoEm);
    expect(lida.candidaturaId, original.candidaturaId);
    expect(lida.copyWith().lida, isTrue);
    expect(lida.copyWith(lida: false).lida, isFalse);
  });

  test('formata dia, mês, hora e minuto com dois dígitos', () {
    final notificacao = NotificacaoModel.fromJson(
      _json()..['criadoEm'] = '2026-01-02T03:04:05.1234567',
    );

    expect(notificacao.dataFormatada, '02/01/2026 às 03:04');
    expect(notificacao.criadoEm.microsecond, 456);
  });

  test('aceita ano bissexto e timestamp UTC válido', () {
    final notificacao = NotificacaoModel.fromJson(
      _json()..['criadoEm'] = '2028-02-29T12:00:00Z',
    );

    expect(notificacao.criadoEm, DateTime.utc(2028, 2, 29, 12));
  });

  for (final (campo, valor) in <(String, Object?)>[
    ('id', null),
    ('id', 0),
    ('id', -1),
    ('id', '15'),
    ('id', 15.0),
    ('titulo', null),
    ('titulo', ' '),
    ('titulo', 123),
    ('mensagem', null),
    ('mensagem', ''),
    ('mensagem', ' '),
    ('lida', null),
    ('lida', 'false'),
    ('lida', 0),
    ('candidaturaId', null),
    ('candidaturaId', 0),
    ('candidaturaId', -1),
    ('candidaturaId', '110'),
    ('criadoEm', null),
    ('criadoEm', 20261007),
    ('criadoEm', 'data inválida'),
    ('criadoEm', '2026-02-30T12:00:00'),
    ('criadoEm', '2026-13-01T12:00:00'),
    ('criadoEm', '2026-10-07T25:00:00'),
    ('criadoEm', '2026-10-07T12:60:00'),
    ('criadoEm', '2026-10-07T12:00:60'),
    ('criadoEm', '2026-10-07T12:00:00+25:00'),
    ('criadoEm', '2026-10-07T12:00:00+03:60'),
  ]) {
    test('JSON inválido em $campo=$valor gera ApiException controlada', () {
      expect(
        () => NotificacaoModel.fromJson(_json()..[campo] = valor),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Resposta inválida do servidor.',
          ),
        ),
      );
    });
  }
}

Map<String, dynamic> _json() => {
  'id': 15,
  'titulo': 'Sua candidatura foi aceita',
  'mensagem': 'A candidatura para a vaga "Desenvolvedor .NET" foi aceita.',
  'lida': false,
  'criadoEm': '2026-10-07T20:30:00',
  'candidaturaId': 110,
};

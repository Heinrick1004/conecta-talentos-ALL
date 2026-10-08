import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/models/perfil_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';

void main() {
  test('converte o perfil completo retornado pela API', () {
    final perfil = PerfilModel.fromJson(_json());

    expect(perfil.id, 1008);
    expect(perfil.nomeCompleto, 'João da Silva');
    expect(perfil.email, 'joao@example.com');
    expect(perfil.telefone, '(15) 99999-9999');
    expect(perfil.cidade, 'Sorocaba');
    expect(perfil.uf, 'SP');
    expect(perfil.habilidades, 'C#; Flutter; SQL');
    expect(perfil.localidade, 'Sorocaba, SP');
    expect(perfil.criadoEm, DateTime(2026, 10, 7, 20));
    expect(perfil.criadoEm.isUtc, isFalse);
  });

  test('aceita campos opcionais nulos sem inventar dados', () {
    final json = _json();
    for (final campo in ['telefone', 'cidade', 'uf', 'habilidades']) {
      json[campo] = null;
    }
    final perfil = PerfilModel.fromJson(json);

    expect(perfil.telefone, isNull);
    expect(perfil.cidade, isNull);
    expect(perfil.uf, isNull);
    expect(perfil.habilidades, isNull);
    expect(perfil.localidade, isEmpty);
    expect(perfil.listaHabilidades, isEmpty);
  });

  test('primeiro nome ignora espaços e demais sobrenomes', () {
    final perfil = PerfilModel.fromJson(
      _json()..['nomeCompleto'] = '  João   Pedro da Silva  ',
    );

    expect(perfil.primeiroNome, 'João');
    expect(perfil.nomeCompleto, 'João   Pedro da Silva');
  });

  test('habilidades aceitam ponto e vírgula, vírgula e quebra de linha', () {
    final perfil = PerfilModel.fromJson(
      _json()..['habilidades'] = ' C# ;, Flutter\n SQL\r\n Git ;; ',
    );

    expect(perfil.listaHabilidades, ['C#', 'Flutter', 'SQL', 'Git']);
  });

  test('localidade aceita somente cidade ou UF', () {
    expect(PerfilModel.fromJson(_json()..['uf'] = null).localidade, 'Sorocaba');
    expect(PerfilModel.fromJson(_json()..['cidade'] = null).localidade, 'SP');
  });

  for (final (campo, valor) in <(String, Object?)>[
    ('id', 0),
    ('id', '1008'),
    ('nomeCompleto', ' '),
    ('nomeCompleto', null),
    ('email', 'email inválido'),
    ('email', null),
    ('criadoEm', null),
    ('criadoEm', 'data inválida'),
    ('criadoEm', '2026-02-30T12:00:00'),
    ('telefone', 123),
  ]) {
    test('perfil inválido em $campo=$valor retorna erro controlado', () {
      expect(
        () => PerfilModel.fromJson(_json()..[campo] = valor),
        throwsA(isA<ApiException>()),
      );
    });
  }
}

Map<String, dynamic> _json() => {
  'id': 1008,
  'nomeCompleto': 'João da Silva',
  'email': 'joao@example.com',
  'telefone': '(15) 99999-9999',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'habilidades': 'C#; Flutter; SQL',
  'criadoEm': '2026-10-07T20:00:00',
};

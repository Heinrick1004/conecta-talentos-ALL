import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';

void main() {
  test(
    'GET envia JWT, converte perfil e notifica início e conclusão',
    () async {
      final service = _service((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/candidato/perfil');
        expect(request.headers['authorization'], 'Bearer jwt-teste');
        return _response(_json());
      });
      final estados = <bool>[];
      service.addListener(() => estados.add(service.carregando));

      await service.carregarPerfil();

      expect(service.perfil!.id, 1008);
      expect(service.perfil!.nomeCompleto, 'João da Silva');
      expect(service.perfil!.listaHabilidades, ['C#', 'Flutter', 'SQL']);
      expect(service.erro, isNull);
      expect(estados, [true, false]);
      service.dispose();
    },
  );

  test('GET usa cache e forceRefresh consulta a API novamente', () async {
    var chamadas = 0;
    final service = _service((_) async {
      chamadas++;
      return _response(_json(nome: 'Pessoa $chamadas'));
    });

    await service.carregarPerfil();
    await service.carregarPerfil();
    expect(chamadas, 1);
    expect(service.perfil!.nomeCompleto, 'Pessoa 1');
    await service.carregarPerfil(forceRefresh: true);
    expect(chamadas, 2);
    expect(service.perfil!.nomeCompleto, 'Pessoa 2');
    service.dispose();
  });

  test('GET simultâneos compartilham a mesma requisição', () async {
    final resposta = Completer<http.Response>();
    var chamadas = 0;
    final service = _service((_) {
      chamadas++;
      return resposta.future;
    });
    final primeira = service.carregarPerfil();
    final segunda = service.carregarPerfil(forceRefresh: true);

    expect(segunda, same(primeira));
    resposta.complete(_response(_json()));
    await Future.wait([primeira, segunda]);

    expect(chamadas, 1);
    expect(service.carregando, isFalse);
    service.dispose();
  });

  test(
    'PUT envia somente cinco campos normalizados e atualiza cache',
    () async {
      final service = _service((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/candidato/perfil');
        expect(request.headers['authorization'], 'Bearer jwt-teste');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'nomeCompleto': 'João Pedro Silva',
          'telefone': '(15) 99999-9999',
          'cidade': 'Campinas',
          'uf': 'SP',
          'habilidades': 'C#; Flutter; SQL',
        });
        expect(body.containsKey('email'), isFalse);
        expect(body.containsKey('id'), isFalse);
        expect(body.containsKey('senha'), isFalse);
        expect(body.containsKey('candidatoId'), isFalse);
        return _response(
          _json(nome: 'João Pedro Silva')..['cidade'] = 'Campinas',
        );
      });
      var notificacoes = 0;
      service.addListener(() => notificacoes++);

      final perfil = await service.atualizarPerfil(
        nomeCompleto: '  João Pedro Silva  ',
        telefone: ' (15) 99999-9999 ',
        cidade: ' Campinas ',
        uf: ' sp ',
        habilidades: ' C# , Flutter\nSQL ;; ',
      );

      expect(service.perfil, same(perfil));
      expect(service.perfil!.primeiroNome, 'João');
      expect(service.perfil!.cidade, 'Campinas');
      expect(service.erro, isNull);
      expect(notificacoes, 1);
      service.dispose();
    },
  );

  test('PUT transforma opcionais vazios em null', () async {
    final service = _service((request) async {
      expect(jsonDecode(request.body), {
        'nomeCompleto': 'João Silva',
        'telefone': null,
        'cidade': null,
        'uf': null,
        'habilidades': null,
      });
      final json = _json(nome: 'João Silva');
      for (final campo in ['telefone', 'cidade', 'uf', 'habilidades']) {
        json[campo] = null;
      }
      return _response(json);
    });

    await service.atualizarPerfil(
      nomeCompleto: ' João Silva ',
      telefone: ' ',
      cidade: '',
      uf: ' ',
      habilidades: ' ;,\n ',
    );

    expect(service.perfil!.telefone, isNull);
    expect(service.perfil!.localidade, isEmpty);
    expect(service.perfil!.listaHabilidades, isEmpty);
    service.dispose();
  });

  for (final metodo in ['GET', 'PUT']) {
    test('$metodo converte 401 para erro de sessão e mantém estado', () async {
      final service = _service((_) async => http.Response('{}', 401));

      await expectLater(
        _executar(service, metodo),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Sua sessão expirou. Faça login novamente.',
              ),
        ),
      );
      expect(service.erro, 'Sua sessão expirou. Faça login novamente.');
      expect(service.carregando, isFalse);
      expect(service.perfil, isNull);
      service.dispose();
    });

    for (final token in <String?>[null, '']) {
      test('$metodo não envia request sem JWT ($token)', () async {
        var chamadas = 0;
        final service = _service((_) async {
          chamadas++;
          return _response(_json());
        }, token: token);

        await expectLater(
          _executar(service, metodo),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
        expect(chamadas, 0);
        service.dispose();
      });
    }

    test('$metodo resposta malformada gera erro controlado', () async {
      final service = _service((_) async => http.Response('[]', 200));

      await expectLater(
        _executar(service, metodo),
        throwsA(isA<ApiException>()),
      );
      expect(service.erro, 'Resposta inválida do servidor.');
      expect(service.carregando, isFalse);
      service.dispose();
    });
  }

  test('GET falho permite retry e preserva cache em refresh falho', () async {
    var chamadas = 0;
    final service = _service((_) async {
      chamadas++;
      return chamadas == 2 ? _response(_json()) : http.Response('{}', 500);
    });

    await expectLater(service.carregarPerfil(), throwsA(isA<ApiException>()));
    await service.carregarPerfil();
    final perfil = service.perfil;
    await expectLater(
      service.carregarPerfil(forceRefresh: true),
      throwsA(isA<ApiException>()),
    );

    expect(chamadas, 3);
    expect(service.perfil, same(perfil));
    expect(service.carregando, isFalse);
    service.dispose();
  });

  test('PUT falho preserva perfil e mensagem retornada pela API', () async {
    final service = _service((request) async {
      return request.method == 'GET'
          ? _response(_json())
          : _response({'erro': 'Informe uma UF com duas letras.'}, 400);
    });
    await service.carregarPerfil();
    final perfil = service.perfil;

    await expectLater(
      service.atualizarPerfil(nomeCompleto: 'João Silva', uf: 'SPA'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Informe uma UF com duas letras.',
        ),
      ),
    );
    expect(service.perfil, same(perfil));
    expect(service.erro, 'Informe uma UF com duas letras.');
    service.dispose();
  });

  test('GET antigo não sobrescreve o resultado de PUT', () async {
    final respostaGet = Completer<http.Response>();
    final service = _service((request) async {
      return request.method == 'GET'
          ? respostaGet.future
          : _response(_json(nome: 'Nome Atualizado'));
    });
    final consulta = service.carregarPerfil();
    await service.atualizarPerfil(nomeCompleto: 'Nome Atualizado');
    respostaGet.complete(_response(_json(nome: 'Nome Antigo')));
    await consulta;

    expect(service.perfil!.nomeCompleto, 'Nome Atualizado');
    expect(service.carregando, isFalse);
    expect(service.erro, isNull);
    service.dispose();
  });

  for (final metodo in ['GET', 'PUT']) {
    test(
      '$metodo pendente não restaura perfil depois de limpar sessão',
      () async {
        final resposta = Completer<http.Response>();
        final service = _service((_) => resposta.future);
        final operacao = _executar(service, metodo);
        service.limparPerfil();
        resposta.complete(_response(_json()));
        await operacao;

        expect(service.perfil, isNull);
        expect(service.erro, isNull);
        expect(service.carregando, isFalse);
        service.dispose();
      },
    );

    test('$metodo pendente não notifica depois de dispose', () async {
      final resposta = Completer<http.Response>();
      final service = _service((_) => resposta.future);
      var notificacoes = 0;
      service.addListener(() => notificacoes++);
      final operacao = _executar(service, metodo);
      final notificacoesAntes = notificacoes;
      service.dispose();
      resposta.complete(_response(_json()));
      await operacao;

      expect(notificacoes, notificacoesAntes);
      expect(service.perfil, isNull);
    });
  }
}

Future<void> _executar(PerfilService service, String metodo) async {
  if (metodo == 'GET') {
    await service.carregarPerfil();
  } else {
    await service.atualizarPerfil(nomeCompleto: 'João Silva');
  }
}

PerfilService _service(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'jwt-teste',
}) => PerfilService(
  authService: _FakeAuthService(token),
  apiClient: ApiClient(client: MockClient(handler)),
);

http.Response _response(Object body, [int statusCode = 200]) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _json({String nome = 'João da Silva'}) => {
  'id': 1008,
  'nomeCompleto': nome,
  'email': 'joao@example.com',
  'telefone': '(15) 99999-9999',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'habilidades': 'C#; Flutter; SQL',
  'criadoEm': '2026-10-07T20:00:00',
};

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.token);

  final String? token;

  @override
  Future<String?> obterToken() async => token;
}

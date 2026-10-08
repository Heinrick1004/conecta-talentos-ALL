import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/notificacao_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/notificacoes_service.dart';

void main() {
  test('GET usa JWT, converte lista real e notifica o carregamento', () async {
    final service = _service((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/candidato/notificacoes');
      expect(request.url.queryParameters, isEmpty);
      expect(request.headers['authorization'], 'Bearer jwt-teste');
      expect(request.body, isEmpty);
      return _response([_json(), _json(id: 16, lida: true)]);
    });
    final estados = <bool>[];
    service.addListener(() => estados.add(service.carregando));

    await service.carregarNotificacoes();

    expect(service.notificacoes, hasLength(2));
    expect(service.notificacoes.first, isA<NotificacaoModel>());
    expect(service.notificacoes.first.id, 15);
    expect(service.notificacoes.first.candidaturaId, 110);
    expect(service.naoLidas, 1);
    expect(service.erro, isNull);
    expect(estados, [true, false]);
    expect(() => service.notificacoes.clear(), throwsUnsupportedError);
    service.dispose();
  });

  for (final vazia in [false, true]) {
    test(
      'GET usa cache inclusive lista vazia=$vazia e permite refresh',
      () async {
        var chamadas = 0;
        final service = _service((_) async {
          chamadas++;
          return _response(vazia ? [] : [_json(id: chamadas)]);
        });

        await service.carregarNotificacoes();
        await service.carregarNotificacoes();
        expect(chamadas, 1);
        await service.carregarNotificacoes(forceRefresh: true);

        expect(chamadas, 2);
        expect(service.notificacoes, vazia ? isEmpty : hasLength(1));
        if (!vazia) expect(service.notificacoes.single.id, 2);
        service.dispose();
      },
    );
  }

  test('GET simultâneos reutilizam a mesma requisição', () async {
    final resposta = Completer<http.Response>();
    var chamadas = 0;
    final service = _service((_) {
      chamadas++;
      return resposta.future;
    });

    final primeira = service.carregarNotificacoes();
    final segunda = service.carregarNotificacoes(forceRefresh: true);
    expect(segunda, same(primeira));
    resposta.complete(_response([_json()]));
    await Future.wait([primeira, segunda]);

    expect(chamadas, 1);
    expect(service.carregando, isFalse);
    service.dispose();
  });

  test('PATCH envia JWT e corpo vazio, atualizando leitura após 204', () async {
    final respostaPatch = Completer<http.Response>();
    final inicioPatch = Completer<void>();
    final service = _service((request) async {
      if (request.method == 'GET') return _response([_json()]);
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/candidato/notificacoes/15/marcar-lida');
      expect(request.url.queryParameters, isEmpty);
      expect(request.headers['authorization'], 'Bearer jwt-teste');
      expect(request.body, isEmpty);
      expect(request.headers.keys, isNot(contains('candidatoId')));
      inicioPatch.complete();
      return respostaPatch.future;
    });
    await service.carregarNotificacoes();
    final original = service.notificacoes.single;

    final marcacao = service.marcarComoLida(15);
    await inicioPatch.future;
    expect(service.estaMarcandoComoLida(15), isTrue);
    expect(service.notificacoes.single, same(original));
    expect(service.notificacoes.single.lida, isFalse);
    expect(service.naoLidas, 1);
    respostaPatch.complete(http.Response('', 204));
    await marcacao;

    expect(service.estaMarcandoComoLida(15), isFalse);
    expect(service.notificacoes.single.lida, isTrue);
    expect(service.notificacoes.single.titulo, original.titulo);
    expect(service.naoLidas, 0);
    expect(service.erro, isNull);
    service.dispose();
  });

  test('clique duplicado durante PATCH envia uma única requisição', () async {
    final resposta = Completer<http.Response>();
    final inicioPatch = Completer<void>();
    var patches = 0;
    final service = _service((request) async {
      if (request.method == 'GET') return _response([_json()]);
      patches++;
      inicioPatch.complete();
      return resposta.future;
    });
    await service.carregarNotificacoes();

    final primeira = service.marcarComoLida(15);
    await service.marcarComoLida(15);
    await service.marcarComoLida(15);
    await inicioPatch.future;
    expect(patches, 1);
    resposta.complete(http.Response('', 204));
    await primeira;
    await service.marcarComoLida(15);

    expect(patches, 1);
    expect(service.notificacoes.single.lida, isTrue);
    service.dispose();
  });

  test('notificação já lida não envia PATCH', () async {
    var chamadas = 0;
    final service = _service((_) async {
      chamadas++;
      return _response([_json(lida: true)]);
    });
    await service.carregarNotificacoes();

    await service.marcarComoLida(15);

    expect(chamadas, 1);
    expect(service.naoLidas, 0);
    expect(service.estaMarcandoComoLida(15), isFalse);
    service.dispose();
  });

  test('contador reage às duas leituras confirmadas', () async {
    final service = _service(
      (request) async => request.method == 'GET'
          ? _response([_json(), _json(id: 16)])
          : http.Response('', 204),
    );
    final contadores = <int>[];
    service.addListener(() => contadores.add(service.naoLidas));
    await service.carregarNotificacoes();
    expect(service.naoLidas, 2);

    await service.marcarComoLida(15);
    expect(service.naoLidas, 1);
    await service.marcarComoLida(16);
    expect(service.naoLidas, 0);
    expect(contadores, containsAllInOrder([2, 1, 0]));
    service.dispose();
  });

  for (final metodo in ['GET', 'PATCH']) {
    for (final token in <String?>[null, '', ' ']) {
      test('$metodo sem JWT ($token) não envia requisição', () async {
        var chamadas = 0;
        final service = _service((_) async {
          chamadas++;
          return http.Response('', 204);
        }, token: token);

        await expectLater(_executar(service, metodo), throwsA(_sessaoExpirada));

        expect(chamadas, 0);
        expect(service.carregando, isFalse);
        expect(service.estaMarcandoComoLida(15), isFalse);
        service.dispose();
      });
    }

    test('$metodo 401 da API informa sessão expirada', () async {
      final service = _service((_) async => http.Response('{}', 401));

      await expectLater(_executar(service, metodo), throwsA(_sessaoExpirada));

      expect(service.notificacoes, isEmpty);
      expect(service.carregando, isFalse);
      expect(service.estaMarcandoComoLida(15), isFalse);
      if (metodo == 'GET') {
        expect(service.erro, 'Sua sessão expirou. Faça login novamente.');
      }
      service.dispose();
    });

    test('$metodo pendente não notifica depois de dispose', () async {
      final resposta = Completer<http.Response>();
      final inicio = Completer<void>();
      final service = _service((_) {
        inicio.complete();
        return resposta.future;
      });
      var notificacoes = 0;
      service.addListener(() => notificacoes++);
      final operacao = _executar(service, metodo);
      await inicio.future;
      final antes = notificacoes;
      service.dispose();
      resposta.complete(
        metodo == 'GET' ? _response([_json()]) : http.Response('', 204),
      );
      await operacao;

      expect(notificacoes, antes);
      expect(service.notificacoes, isEmpty);
    });
  }

  for (final codigo in [401, 403, 404]) {
    test('PATCH $codigo preserva leitura e libera nova tentativa', () async {
      var patches = 0;
      final service = _service((request) async {
        if (request.method == 'GET') return _response([_json()]);
        patches++;
        return patches == 1
            ? _response({'erro': 'Notificação indisponível.'}, codigo)
            : http.Response('', 204);
      });
      await service.carregarNotificacoes();
      final original = service.notificacoes.single;

      await expectLater(
        service.marcarComoLida(15),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', codigo)
              .having(
                (error) => error.message,
                'message',
                codigo == 401
                    ? 'Sua sessão expirou. Faça login novamente.'
                    : 'Notificação indisponível.',
              ),
        ),
      );

      expect(service.notificacoes.single, same(original));
      expect(service.notificacoes.single.lida, isFalse);
      expect(service.naoLidas, 1);
      expect(service.estaMarcandoComoLida(15), isFalse);
      await service.marcarComoLida(15);
      expect(patches, 2);
      expect(service.notificacoes.single.lida, isTrue);
      service.dispose();
    });
  }

  test('PATCH 404 sem mensagem retorna erro controlado', () async {
    final service = _service((_) async => http.Response('', 404));

    await expectLater(
      service.marcarComoLida(15),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having(
              (error) => error.message,
              'message',
              'Recurso não encontrado.',
            ),
      ),
    );
    service.dispose();
  });

  test('GET falho permite retry e refresh falho preserva lista', () async {
    var chamadas = 0;
    final service = _service((_) async {
      chamadas++;
      return chamadas == 2 || chamadas == 4
          ? _response([_json()])
          : http.Response('{}', 500);
    });

    await expectLater(
      service.carregarNotificacoes(),
      throwsA(isA<ApiException>()),
    );
    expect(service.erro, isNotNull);
    await service.carregarNotificacoes();
    final original = service.notificacoes.single;
    await expectLater(
      service.carregarNotificacoes(forceRefresh: true),
      throwsA(isA<ApiException>()),
    );
    expect(service.notificacoes.single, same(original));
    expect(service.carregando, isFalse);
    await service.carregarNotificacoes(forceRefresh: true);

    expect(chamadas, 4);
    expect(service.erro, isNull);
    expect(service.naoLidas, 1);
    service.dispose();
  });

  for (final corpo in ['{}', 'null', '[null]', '[{"id":15}]']) {
    test('GET resposta inválida $corpo retorna erro controlado', () async {
      final service = _service((_) async => http.Response(corpo, 200));

      await expectLater(
        service.carregarNotificacoes(),
        throwsA(isA<ApiException>()),
      );

      expect(service.erro, 'Não foi possível carregar suas notificações.');
      expect(service.carregando, isFalse);
      expect(service.notificacoes, isEmpty);
      service.dispose();
    });
  }

  test('GET antigo não desfaz PATCH confirmado enquanto consulta', () async {
    final respostaGet = Completer<http.Response>();
    final inicioGet = Completer<void>();
    var gets = 0;
    final service = _service((request) async {
      if (request.method == 'PATCH') return http.Response('', 204);
      gets++;
      if (gets == 1) return _response([_json()]);
      inicioGet.complete();
      return respostaGet.future;
    });
    await service.carregarNotificacoes();

    final consulta = service.carregarNotificacoes(forceRefresh: true);
    await inicioGet.future;
    await service.marcarComoLida(15);
    respostaGet.complete(_response([_json(), _json(id: 16)]));
    await consulta;

    expect(service.notificacoes, hasLength(2));
    expect(service.notificacoes.first.lida, isTrue);
    expect(service.notificacoes.last.lida, isFalse);
    expect(service.naoLidas, 1);
    expect(service.carregando, isFalse);
    service.dispose();
  });

  test('limpar elimina lista, erro, loading, IDs e cache', () async {
    final patch = Completer<http.Response>();
    final get = Completer<http.Response>();
    final inicioGet = Completer<void>();
    final inicioPatch = Completer<void>();
    var gets = 0;
    final service = _service((request) async {
      if (request.method == 'PATCH') {
        inicioPatch.complete();
        return patch.future;
      }
      gets++;
      if (gets == 2) return http.Response('{}', 500);
      if (gets == 3) {
        inicioGet.complete();
        return get.future;
      }
      return _response([_json()]);
    });
    await service.carregarNotificacoes();
    await expectLater(
      service.carregarNotificacoes(forceRefresh: true),
      throwsA(isA<ApiException>()),
    );
    expect(service.erro, isNotNull);
    service.limparNotificacoes();
    expect(service.erro, isNull);
    // Após limpar, a consulta usa a API mesmo que antes houvesse cache.
    final consultaAntiga = service.carregarNotificacoes();
    await inicioGet.future;
    final marcacaoAntiga = service.marcarComoLida(15);
    await inicioPatch.future;
    expect(service.carregando, isTrue);
    expect(service.estaMarcandoComoLida(15), isTrue);
    var notificacoes = 0;
    service.addListener(() => notificacoes++);

    service.limparNotificacoes();

    expect(service.notificacoes, isEmpty);
    expect(service.erro, isNull);
    expect(service.carregando, isFalse);
    expect(service.naoLidas, 0);
    expect(service.estaMarcandoComoLida(15), isFalse);
    expect(notificacoes, 1);
    await service.carregarNotificacoes();
    expect(gets, 4);
    expect(service.notificacoes.single.lida, isFalse);
    final atual = service.notificacoes.single;
    final notificacoesAntes = notificacoes;
    get.complete(_response([_json(id: 100)]));
    patch.complete(http.Response('', 204));
    await Future.wait([consultaAntiga, marcacaoAntiga]);

    expect(service.notificacoes.single, same(atual));
    expect(service.notificacoes.single.lida, isFalse);
    expect(notificacoes, notificacoesAntes);
    service.dispose();
  });

  test('PATCH antigo não limpa marcação da nova conta com mesmo ID', () async {
    final patchAntigo = Completer<http.Response>();
    final patchNovo = Completer<http.Response>();
    final inicioAntigo = Completer<void>();
    final inicioNovo = Completer<void>();
    var patches = 0;
    final service = _service((request) async {
      if (request.method == 'GET') return _response([_json()]);
      patches++;
      if (patches == 1) {
        inicioAntigo.complete();
        return patchAntigo.future;
      }
      inicioNovo.complete();
      return patchNovo.future;
    });
    await service.carregarNotificacoes();
    final primeira = service.marcarComoLida(15);
    await inicioAntigo.future;
    service.limparNotificacoes();
    await service.carregarNotificacoes();
    final segunda = service.marcarComoLida(15);
    await inicioNovo.future;

    patchAntigo.complete(http.Response('', 204));
    await primeira;

    expect(service.estaMarcandoComoLida(15), isTrue);
    expect(service.notificacoes.single.lida, isFalse);
    patchNovo.complete(http.Response('', 204));
    await segunda;
    expect(service.estaMarcandoComoLida(15), isFalse);
    expect(service.notificacoes.single.lida, isTrue);
    expect(patches, 2);
    service.dispose();
  });

  test(
    'erro GET da conta anterior não substitui estado da nova sessão',
    () async {
      final respostaAntiga = Completer<http.Response>();
      final inicio = Completer<void>();
      var gets = 0;
      final service = _service((_) async {
        gets++;
        if (gets == 1) {
          inicio.complete();
          return respostaAntiga.future;
        }
        return _response([_json(id: 16)]);
      });
      final antiga = service.carregarNotificacoes();
      await inicio.future;
      service.limparNotificacoes();
      await service.carregarNotificacoes();
      final expectativa = expectLater(antiga, throwsA(_sessaoExpirada));

      respostaAntiga.complete(http.Response('{}', 401));
      await expectativa;

      expect(service.notificacoes.single.id, 16);
      expect(service.erro, isNull);
      expect(service.carregando, isFalse);
      service.dispose();
    },
  );

  for (final metodo in ['GET', 'PATCH']) {
    test(
      '$metodo não envia request se sessão limpar durante leitura JWT',
      () async {
        final token = Completer<String?>();
        var requests = 0;
        final service = NotificacoesService(
          authService: _PendingAuthService(token.future),
          apiClient: ApiClient(
            client: MockClient((_) async {
              requests++;
              return http.Response('', 204);
            }),
          ),
        );
        final operacao = _executar(service, metodo);
        service.limparNotificacoes();
        token.complete('jwt-teste');
        await operacao;

        expect(requests, 0);
        expect(service.notificacoes, isEmpty);
        expect(service.carregando, isFalse);
        expect(service.estaMarcandoComoLida(15), isFalse);
        service.dispose();
      },
    );
  }

  test('não envia PATCH para ID inválido', () async {
    var requests = 0;
    final service = _service((_) async {
      requests++;
      return http.Response('', 204);
    });

    await expectLater(service.marcarComoLida(0), throwsA(isA<ApiException>()));
    await expectLater(service.marcarComoLida(-1), throwsA(isA<ApiException>()));

    expect(requests, 0);
    expect(service.estaMarcandoComoLida(0), isFalse);
    service.dispose();
  });
}

Future<void> _executar(NotificacoesService service, String metodo) =>
    metodo == 'GET'
    ? service.carregarNotificacoes()
    : service.marcarComoLida(15);

Matcher get _sessaoExpirada => isA<ApiException>()
    .having((error) => error.statusCode, 'statusCode', 401)
    .having(
      (error) => error.message,
      'message',
      'Sua sessão expirou. Faça login novamente.',
    );

NotificacoesService _service(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'jwt-teste',
}) => NotificacoesService(
  authService: _FakeAuthService(token),
  apiClient: ApiClient(client: MockClient(handler)),
);

http.Response _response(Object body, [int statusCode = 200]) => http.Response(
  jsonEncode(body),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _json({int id = 15, bool lida = false}) => {
  'id': id,
  'titulo': 'Sua candidatura foi aceita',
  'mensagem': 'A candidatura para a vaga "Desenvolvedor .NET" foi aceita.',
  'lida': lida,
  'criadoEm': '2026-10-07T20:30:00',
  'candidaturaId': 110,
};

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.token);

  final String? token;

  @override
  Future<String?> obterToken() async => token;
}

class _PendingAuthService extends AuthService {
  _PendingAuthService(this.token);

  final Future<String?> token;

  @override
  Future<String?> obterToken() => token;
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';

void main() {
  test('GET lista candidaturas com JWT e converte dados reais', () async {
    final service = _service((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/candidato/candidaturas');
      expect(request.headers['authorization'], 'Bearer jwt-teste');
      return http.Response(
        jsonEncode([
          _json(),
          _json()..['status'] = 'Aceita',
          _json()..['status'] = 'Recusada',
        ]),
        200,
      );
    });

    final candidaturas = await service.listarCandidaturas();

    expect(candidaturas, hasLength(3));
    expect(candidaturas.first.id, 10);
    expect(candidaturas.first.vaga.id, 7);
    expect(candidaturas.map((item) => item.textoStatus), [
      'Em análise',
      'Selecionado',
      'Rejeitado',
    ]);
  });

  test('GET sem candidaturas retorna lista vazia', () async {
    final service = _service((_) async => http.Response('[]', 200));

    expect(await service.listarCandidaturas(), isEmpty);
  });

  test('POST envia somente vagaId com JWT e converte resposta 201', () async {
    var requests = 0;
    final service = _service((request) async {
      requests++;
      expect(request.method, 'POST');
      expect(request.url.path, '/api/candidato/candidaturas');
      expect(request.headers['authorization'], 'Bearer jwt-teste');
      expect(jsonDecode(request.body), {'vagaId': 7});
      return http.Response(jsonEncode(_json()), 201);
    });

    final candidatura = await service.criarCandidatura(7);

    expect(requests, 1);
    expect(candidatura.id, 10);
    expect(candidatura.vaga.id, 7);
    expect(candidatura.status, CandidaturaStatus.emAnalise);
  });

  for (final operacao in ['GET', 'POST']) {
    test('$operacao converte 401 para sessão expirada', () async {
      final service = _service((_) async => http.Response('{}', 401));

      await expectLater(
        _executar(service, operacao),
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
    });

    for (final token in <String?>[null, '']) {
      test('$operacao não chama API sem JWT ($token)', () async {
        var requests = 0;
        final service = _service((_) async {
          requests++;
          return http.Response('[]', 200);
        }, token: token);

        await expectLater(
          _executar(service, operacao),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              401,
            ),
          ),
        );
        expect(requests, 0);
      });
    }
  }

  for (final (codigo, mensagem) in [
    (400, 'Esta vaga não está mais aceitando candidaturas'),
    (404, 'Vaga não encontrada'),
    (409, 'Você já se candidatou a esta vaga'),
  ]) {
    test('POST preserva mensagem da API para erro $codigo', () async {
      var requests = 0;
      final service = _service((_) async {
        requests++;
        return http.Response(jsonEncode({'erro': mensagem}), codigo);
      });

      await expectLater(
        service.criarCandidatura(7),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', codigo)
              .having((error) => error.message, 'message', mensagem),
        ),
      );
      expect(requests, 1);
    });
  }

  test('POST 409 sem mensagem usa texto de candidatura duplicada', () async {
    final service = _service((_) async => http.Response('{}', 409));

    await expectLater(
      service.criarCandidatura(7),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'Você já se candidatou a esta vaga.',
            ),
      ),
    );
  });

  test('não cria candidatura com vaga sem ID válido', () async {
    var requests = 0;
    final service = _service((_) async {
      requests++;
      return http.Response(jsonEncode(_json()), 201);
    });

    await expectLater(
      service.criarCandidatura(0),
      throwsA(isA<ApiException>()),
    );
    expect(requests, 0);
  });

  for (final corpo in ['{}', '[null]', '[{"id":10,"vaga":{}}]']) {
    test('GET resposta inválida $corpo gera erro controlado', () async {
      final service = _service((_) async => http.Response(corpo, 200));

      await expectLater(
        service.listarCandidaturas(),
        throwsA(isA<ApiException>()),
      );
    });
  }

  test('POST resposta inválida gera erro controlado', () async {
    final service = _service((_) async => http.Response('null', 201));

    await expectLater(
      service.criarCandidatura(7),
      throwsA(isA<ApiException>()),
    );
  });
}

Future<Object> _executar(CandidaturasService service, String operacao) =>
    operacao == 'GET'
    ? service.listarCandidaturas()
    : service.criarCandidatura(7);

CandidaturasService _service(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'jwt-teste',
}) => CandidaturasService(
  authService: _FakeAuthService(token),
  apiClient: ApiClient(client: MockClient(handler)),
);

Map<String, dynamic> _json() => {
  'id': 10,
  'status': 'Pendente',
  'dataCandidatura': '2026-10-07T23:30:00',
  'atualizadoEm': '2026-10-07T23:30:00',
  'vaga': {
    'id': 7,
    'titulo': 'Desenvolvedor .NET',
    'nomeFantasiaEmpresa': 'Empresa X',
    'cidade': 'Sorocaba',
    'uf': 'SP',
    'modalidade': 'Hibrido',
  },
};

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.token);

  final String? token;

  @override
  Future<String?> obterToken() async => token;
}

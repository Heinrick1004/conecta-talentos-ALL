import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/auth_models.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/token_storage.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';

void main() {
  test('lista vagas com JWT e converte o JSON para VagaMock', () async {
    var authorizationHeader = '';
    final service = _service((request) async {
      expect(request.url.path, '/api/candidato/vagas');
      authorizationHeader = request.headers['authorization'] ?? '';
      return http.Response(
        jsonEncode([_vagaJson()]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final vagas = await service.listarVagas();

    expect(authorizationHeader, 'Bearer test-token');
    expect(vagas, hasLength(1));
    expect(vagas.first.id, 42);
    expect(vagas.first.titulo, 'Desenvolvedor .NET');
    expect(vagas.first.empresa, 'XP Tecnologia');
    expect(vagas.first.local, 'Sorocaba, SP');
    expect(vagas.first.modalidade, 'Híbrido');
    expect(vagas.first.sigla, 'XT');
    expect(vagas.first.iconeModalidade, Icons.swap_horiz_rounded);
    expect(vagas.first.indiceDestaque, 42);
    expect(vagas.first.dataInicio, DateTime(2026, 8, 10));
    expect(vagas.first.dataFim, DateTime(2026, 10, 31));
    expect(vagas.first.jaCandidatado, isTrue);
    expect(vagas.first.favoritada, isTrue);
  });

  test('envia filtros de cidade e modalidade como query parameters', () async {
    final service = _service((request) async {
      expect(request.url.path, '/api/candidato/vagas');
      expect(request.url.queryParameters, {
        'cidade': 'Sorocaba',
        'modalidade': 'Remoto',
      });
      return http.Response('[]', 200);
    });

    expect(
      await service.listarVagas(cidade: ' Sorocaba ', modalidade: 'Remoto'),
      isEmpty,
    );
  });

  test('carrega uma vaga pelo endpoint de detalhes', () async {
    final service = _service((request) async {
      expect(request.url.path, '/api/candidato/vagas/42');
      return http.Response(jsonEncode(_vagaJson()), 200);
    });

    final vaga = await service.obterVaga(42);

    expect(vaga.id, 42);
    expect(vaga.requisitos, ['C#', '.NET', 'SQL', 'Git']);
  });

  test('401 em endpoint de vagas informa que a sessão expirou', () async {
    final service = _service(
      (_) async => http.Response('{"erro":"Não autorizado."}', 401),
    );

    await expectLater(
      service.listarVagas(),
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

  test('não consulta a API quando não há JWT', () async {
    var requestCount = 0;
    final service = _service((_) async {
      requestCount++;
      return http.Response('[]', 200);
    }, token: null);

    await expectLater(
      service.listarVagas(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(requestCount, 0);
  });

  test('login converte 401 para mensagem de credenciais inválidas', () async {
    final storage = _MemorySessionStorage()..token = 'test-token';
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient(
          (_) async => http.Response('{"erro":"Não autorizado."}', 401),
        ),
      ),
      tokenStorage: storage,
    );

    await expectLater(
      authService.login(email: 'teste@example.com', senha: 'senha-incorreta'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having(
              (error) => error.message,
              'message',
              'E-mail ou senha inválidos.',
            ),
      ),
    );
  });
}

VagasService _service(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'test-token',
}) {
  return VagasService(
    apiClient: ApiClient(client: MockClient(handler)),
    authService: AuthService(
      tokenStorage: _MemorySessionStorage()..token = token,
    ),
  );
}

Map<String, Object?> _vagaJson() => {
  'id': 42,
  'titulo': 'Desenvolvedor .NET',
  'descricao': 'Desenvolvimento de APIs.',
  'requisitos': ' C#; .NET\r\nSQL;; Git ;\n',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'modalidade': 'Hibrido',
  'dataInicio': '2026-08-10',
  'dataFim': '2026-10-31',
  'nomeFantasiaEmpresa': 'XP Tecnologia',
  'jaCandidatado': true,
  'favoritada': true,
};

class _MemorySessionStorage implements SessionStorage {
  String? token;

  @override
  Future<void> limparSessao() async {
    token = null;
  }

  @override
  Future<String?> obterToken() async => token;

  @override
  Future<void> salvarSessao(AuthResponse response) async {
    token = response.token;
  }
}

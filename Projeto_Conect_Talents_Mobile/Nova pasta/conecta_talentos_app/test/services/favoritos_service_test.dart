import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/vaga_model.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';

void main() {
  test(
    'lista favoritos autenticados e converte a resposta para VagaModel',
    () async {
      late http.Request request;
      final service = FavoritosService(
        authService: _FakeAuthService('jwt-teste'),
        apiClient: ApiClient(
          client: MockClient((received) async {
            request = received;
            return http.Response(jsonEncode([_vagaJson()]), 200);
          }),
        ),
      );

      final favoritos = await service.listarFavoritos();

      expect(request.method, 'GET');
      expect(request.url.path, '/api/candidato/favoritos');
      expect(request.headers['authorization'], 'Bearer jwt-teste');
      expect(favoritos, hasLength(1));
      expect(favoritos.single.id, 7);
      expect(favoritos.single.titulo, 'Analista mobile');
      expect(favoritos.single.favoritada, isTrue);
    },
  );

  test('adiciona favorito com POST autenticado e corpo vazio', () async {
    late http.Request request;
    final service = FavoritosService(
      authService: _FakeAuthService('jwt-teste'),
      apiClient: ApiClient(
        client: MockClient((received) async {
          request = received;
          return http.Response('', 204);
        }),
      ),
    );

    await service.adicionarFavorito(7);

    expect(request.method, 'POST');
    expect(request.url.path, '/api/candidato/favoritos/7');
    expect(request.headers['authorization'], 'Bearer jwt-teste');
    expect(request.body, '{}');
  });

  test('remove favorito com DELETE autenticado', () async {
    late http.Request request;
    final service = FavoritosService(
      authService: _FakeAuthService('jwt-teste'),
      apiClient: ApiClient(
        client: MockClient((received) async {
          request = received;
          return http.Response('', 204);
        }),
      ),
    );

    await service.removerFavorito(7);

    expect(request.method, 'DELETE');
    expect(request.url.path, '/api/candidato/favoritos/7');
    expect(request.headers['authorization'], 'Bearer jwt-teste');
  });

  test('converte 401 da API para sessão expirada', () async {
    final service = FavoritosService(
      authService: _FakeAuthService('jwt-teste'),
      apiClient: ApiClient(
        client: MockClient((_) async => http.Response('{}', 401)),
      ),
    );

    await expectLater(
      service.listarFavoritos(),
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

  test('não envia requisição quando não há JWT', () async {
    var requestCount = 0;
    final service = FavoritosService(
      authService: _FakeAuthService(null),
      apiClient: ApiClient(
        client: MockClient((_) async {
          requestCount++;
          return http.Response('[]', 200);
        }),
      ),
    );

    await expectLater(
      service.listarFavoritos(),
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
    expect(requestCount, 0);
  });

  test('copyWith atualiza somente os estados solicitados', () {
    final vaga = VagaModel.fromJson(_vagaJson());
    final atualizada = vaga.copyWith(jaCandidatado: true);

    expect(atualizada.id, vaga.id);
    expect(atualizada.titulo, vaga.titulo);
    expect(atualizada.favoritada, isTrue);
    expect(atualizada.jaCandidatado, isTrue);
  });
}

Map<String, Object> _vagaJson() => {
  'id': 7,
  'titulo': 'Analista mobile',
  'descricao': 'Desenvolvimento Flutter',
  'requisitos': 'Flutter; APIs REST',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'modalidade': 'Remoto',
  'nomeFantasiaEmpresa': 'Empresa Teste',
  'jaCandidatado': false,
  'favoritada': true,
};

class _FakeAuthService extends AuthService {
  _FakeAuthService(this.token);

  final String? token;

  @override
  Future<String?> obterToken() async => token;
}

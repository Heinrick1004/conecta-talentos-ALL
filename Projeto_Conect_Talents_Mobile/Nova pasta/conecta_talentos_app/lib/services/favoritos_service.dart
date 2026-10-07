import '../mock/mock_vagas.dart';
import 'api_client.dart';
import 'auth_service.dart';

class FavoritosService {
  FavoritosService({ApiClient? apiClient, required this._authService})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final AuthService _authService;

  Future<List<VagaMock>> listarFavoritos() async {
    final response = await _comToken(
      (token) => _apiClient.getJson('/api/candidato/favoritos', token: token),
    );
    if (response is! List) {
      throw const ApiException('Resposta inválida do servidor.');
    }

    return response
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ApiException('Resposta inválida do servidor.');
          }
          return VagaMock.fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> adicionarFavorito(int vagaId) async {
    await _comToken(
      (token) => _apiClient.postJson(
        '/api/candidato/favoritos/$vagaId',
        body: const {},
        token: token,
      ),
    );
  }

  Future<void> removerFavorito(int vagaId) async {
    await _comToken(
      (token) => _apiClient.deleteJson(
        '/api/candidato/favoritos/$vagaId',
        token: token,
      ),
    );
  }

  Future<T> _comToken<T>(Future<T> Function(String token) requisicao) async {
    final token = await _authService.obterToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sua sessão expirou. Faça login novamente.',
        statusCode: 401,
      );
    }

    try {
      return await requisicao(token);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        throw const ApiException(
          'Sua sessão expirou. Faça login novamente.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }
}

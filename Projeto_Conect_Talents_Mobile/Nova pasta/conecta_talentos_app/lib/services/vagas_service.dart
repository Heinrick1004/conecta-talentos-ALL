import '../mock/mock_vagas.dart';
import 'api_client.dart';
import 'auth_service.dart';

class VagasService {
  VagasService({ApiClient? apiClient, required this._authService})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final AuthService _authService;

  Future<List<VagaMock>> listarVagas({
    String? cidade,
    String? modalidade,
  }) async {
    final queryParameters = <String, String>{
      if (cidade != null && cidade.trim().isNotEmpty) 'cidade': cidade.trim(),
      if (modalidade != null && modalidade.trim().isNotEmpty)
        'modalidade': modalidade.trim(),
    };
    final query = queryParameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: queryParameters).query}';
    final response = await _get('/api/candidato/vagas$query');
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

  Future<VagaMock> obterVaga(int id) async {
    final response = await _get('/api/candidato/vagas/$id');
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return VagaMock.fromJson(response);
  }

  Future<dynamic> _get(String path) async {
    final token = await _authService.obterToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sua sessão expirou. Faça login novamente.',
        statusCode: 401,
      );
    }

    try {
      return await _apiClient.getJson(path, token: token);
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

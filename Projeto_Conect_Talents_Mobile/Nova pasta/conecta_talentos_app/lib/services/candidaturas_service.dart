import '../models/candidatura_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class CandidaturasService {
  CandidaturasService({required this._authService, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<List<CandidaturaModel>> listarCandidaturas() async {
    final response = await _comToken(
      (token) =>
          _apiClient.getJson('/api/candidato/candidaturas', token: token),
    );
    if (response is! List) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return response.map(_candidatura).toList(growable: false);
  }

  Future<CandidaturaModel> criarCandidatura(int vagaId) async {
    if (vagaId <= 0) {
      throw const ApiException('Informe uma vaga válida.');
    }
    final response = await _comToken(
      (token) => _apiClient.postJson(
        '/api/candidato/candidaturas',
        body: {'vagaId': vagaId},
        token: token,
      ),
    );
    return _candidatura(response);
  }

  CandidaturaModel _candidatura(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return CandidaturaModel.fromJson(response);
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
      if (error.statusCode == 409 &&
          error.message == 'Já existe uma conta cadastrada com esses dados.') {
        throw const ApiException(
          'Você já se candidatou a esta vaga.',
          statusCode: 409,
        );
      }
      rethrow;
    }
  }
}

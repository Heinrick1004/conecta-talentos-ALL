import 'dart:convert';

import '../models/auth_models.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, SessionStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final SessionStorage _tokenStorage;

  Future<AuthResponse> login({
    required String email,
    required String senha,
  }) async {
    final result = await _apiClient.postJson(
      '/api/auth/candidato/login',
      body: {'email': email, 'senha': senha},
    );
    if (result is! Map<String, dynamic>) {
      throw const ApiException('Resposta inválida do servidor.');
    }

    try {
      final authResponse = AuthResponse.fromJson(result);
      if (authResponse.token.isEmpty) {
        throw const FormatException('Token ausente');
      }
      await _tokenStorage.salvarSessao(authResponse);
      return authResponse;
    } on TypeError {
      throw const ApiException('Resposta inválida do servidor.');
    } on FormatException {
      throw const ApiException('Resposta inválida do servidor.');
    }
  }

  Future<void> registrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    await _apiClient.postJson(
      '/api/auth/candidato/registrar',
      body: {'nomeCompleto': nomeCompleto, 'email': email, 'senha': senha},
    );
  }

  Future<void> logout() => _tokenStorage.limparSessao();

  Future<bool> possuiSessaoValida() async {
    final token = await _tokenStorage.obterToken();
    if (token == null || token.isEmpty || !_tokenNaoExpirado(token)) {
      await _tokenStorage.limparSessao();
      return false;
    }
    return true;
  }

  bool _tokenNaoExpirado(String token) {
    final segmentos = token.split('.');
    if (segmentos.length != 3) return false;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segmentos[1])),
      );
      final dados = jsonDecode(payload);
      if (dados is! Map<String, dynamic>) return false;
      final exp = dados['exp'];
      final expSegundos = exp is num
          ? exp.toInt()
          : exp is String
          ? int.tryParse(exp)
          : null;
      if (expSegundos == null) return false;
      final agoraSegundos = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expSegundos > agoraSegundos;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }
}

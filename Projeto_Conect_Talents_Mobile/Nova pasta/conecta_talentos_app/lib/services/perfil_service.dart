import 'package:flutter/foundation.dart';

import '../models/perfil_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class PerfilService extends ChangeNotifier {
  PerfilService({required this._authService, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AuthService _authService;
  final ApiClient _apiClient;
  PerfilModel? _perfil;
  bool _carregando = false;
  String? _erro;
  Future<void>? _consultaEmAndamento;
  int _revisao = 0;
  int _sessao = 0;
  bool _disposed = false;

  PerfilModel? get perfil => _perfil;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> carregarPerfil({bool forceRefresh = false}) {
    if (_disposed) return Future<void>.value();
    if (_consultaEmAndamento != null) return _consultaEmAndamento!;
    if (_perfil != null && !forceRefresh) return Future<void>.value();

    final revisao = ++_revisao;
    _carregando = true;
    _erro = null;
    final consulta = _buscarPerfil(revisao);
    _consultaEmAndamento = consulta;
    notifyListeners();
    return consulta;
  }

  Future<void> _buscarPerfil(int revisao) async {
    try {
      final response = await _comToken(
        (token) => _apiClient.getJson('/api/candidato/perfil', token: token),
      );
      final perfil = _converterPerfil(response);
      if (_consultaAtual(revisao)) _perfil = perfil;
    } catch (error) {
      final apiError = error is ApiException
          ? error
          : const ApiException('Não foi possível carregar seu perfil.');
      if (_consultaAtual(revisao)) _erro = apiError.message;
      throw apiError;
    } finally {
      if (_consultaAtual(revisao)) {
        _consultaEmAndamento = null;
        _carregando = false;
        notifyListeners();
      }
    }
  }

  Future<PerfilModel> atualizarPerfil({
    required String nomeCompleto,
    String? telefone,
    String? cidade,
    String? uf,
    String? habilidades,
  }) async {
    final sessao = _sessao;
    try {
      final response = await _comToken(
        (token) => _apiClient.putJson(
          '/api/candidato/perfil',
          body: {
            'nomeCompleto': nomeCompleto.trim(),
            'telefone': _opcional(telefone),
            'cidade': _opcional(cidade),
            'uf': _opcional(uf)?.toUpperCase(),
            'habilidades': _habilidades(habilidades),
          },
          token: token,
        ),
      );
      final perfil = _converterPerfil(response);
      if (!_disposed && sessao == _sessao) {
        // Um GET iniciado antes do PUT não pode restaurar o perfil antigo.
        _revisao++;
        _consultaEmAndamento = null;
        _carregando = false;
        _perfil = perfil;
        _erro = null;
        notifyListeners();
      }
      return perfil;
    } catch (error) {
      final apiError = error is ApiException
          ? error
          : const ApiException('Não foi possível atualizar seu perfil.');
      if (!_disposed && sessao == _sessao) {
        _erro = apiError.message;
        notifyListeners();
      }
      throw apiError;
    }
  }

  void limparPerfil() {
    if (_disposed) return;
    _sessao++;
    _revisao++;
    _consultaEmAndamento = null;
    _perfil = null;
    _carregando = false;
    _erro = null;
    notifyListeners();
  }

  bool _consultaAtual(int revisao) => !_disposed && revisao == _revisao;

  PerfilModel _converterPerfil(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return PerfilModel.fromJson(response);
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

  static String? _opcional(String? value) {
    final texto = value?.trim();
    return texto == null || texto.isEmpty ? null : texto;
  }

  static String? _habilidades(String? value) {
    final itens = (value ?? '')
        .split(RegExp(r'[;,\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    return _opcional(itens.join('; '));
  }

  @override
  void dispose() {
    _disposed = true;
    _sessao++;
    _revisao++;
    _consultaEmAndamento = null;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';

import '../models/notificacao_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class NotificacoesService extends ChangeNotifier {
  NotificacoesService({required this._authService, ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final AuthService _authService;
  final ApiClient _apiClient;
  List<NotificacaoModel> _notificacoes = [];
  bool _carregando = false;
  bool _carregadas = false;
  String? _erro;
  final Set<int> _marcandoComoLida = {};
  final Set<int> _leiturasDuranteConsulta = {};
  Future<void>? _consultaEmAndamento;
  int _sessao = 0;
  bool _disposed = false;

  List<NotificacaoModel> get notificacoes => List.unmodifiable(_notificacoes);
  bool get carregando => _carregando;
  String? get erro => _erro;
  int get naoLidas => _notificacoes.where((item) => !item.lida).length;

  bool estaMarcandoComoLida(int id) => _marcandoComoLida.contains(id);

  Future<void> carregarNotificacoes({bool forceRefresh = false}) {
    if (_disposed) return Future<void>.value();
    if (_consultaEmAndamento != null) return _consultaEmAndamento!;
    if (_carregadas && !forceRefresh) return Future<void>.value();

    _carregando = true;
    _erro = null;
    _leiturasDuranteConsulta.clear();
    final consulta = _buscarNotificacoes(_sessao);
    _consultaEmAndamento = consulta;
    notifyListeners();
    return consulta;
  }

  Future<void> _buscarNotificacoes(int sessao) async {
    try {
      final token = await _obterToken();
      if (!_sessaoAtual(sessao)) return;
      final response = await _apiClient.getJson(
        '/api/candidato/notificacoes',
        token: token,
      );
      if (response is! List) {
        throw const ApiException('Resposta inválida do servidor.');
      }
      final notificacoes = response
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const ApiException('Resposta inválida do servidor.');
            }
            return NotificacaoModel.fromJson(item);
          })
          .toList(growable: false);
      if (_sessaoAtual(sessao)) {
        // Um GET anterior ao PATCH não pode desfazer uma leitura confirmada.
        _notificacoes = notificacoes
            .map(
              (item) => _leiturasDuranteConsulta.contains(item.id)
                  ? item.copyWith(lida: true)
                  : item,
            )
            .toList(growable: false);
        _carregadas = true;
      }
    } catch (error) {
      final apiError = _erroControlado(
        error,
        'Não foi possível carregar suas notificações.',
      );
      if (_sessaoAtual(sessao)) {
        _erro = apiError.statusCode == 401
            ? apiError.message
            : 'Não foi possível carregar suas notificações.';
      }
      throw apiError;
    } finally {
      if (_sessaoAtual(sessao)) {
        _consultaEmAndamento = null;
        _carregando = false;
        _leiturasDuranteConsulta.clear();
        notifyListeners();
      }
    }
  }

  Future<void> marcarComoLida(int notificacaoId) {
    if (_disposed) return Future<void>.value();
    if (notificacaoId <= 0) {
      return Future<void>.error(
        const ApiException('Informe uma notificação válida.'),
      );
    }
    if (_marcandoComoLida.contains(notificacaoId) ||
        _notificacoes.any((item) => item.id == notificacaoId && item.lida)) {
      return Future<void>.value();
    }

    final sessao = _sessao;
    _marcandoComoLida.add(notificacaoId);
    notifyListeners();
    return _marcarComoLida(notificacaoId, sessao);
  }

  Future<void> _marcarComoLida(int id, int sessao) async {
    try {
      final token = await _obterToken();
      if (!_sessaoAtual(sessao)) return;
      await _apiClient.patchJson(
        '/api/candidato/notificacoes/$id/marcar-lida',
        token: token,
      );
      if (_sessaoAtual(sessao)) {
        if (_carregando) _leiturasDuranteConsulta.add(id);
        _notificacoes = _notificacoes
            .map((item) => item.id == id ? item.copyWith(lida: true) : item)
            .toList(growable: false);
      }
    } catch (error) {
      throw _erroControlado(
        error,
        'Não foi possível marcar a notificação como lida.',
      );
    } finally {
      if (_sessaoAtual(sessao)) {
        _marcandoComoLida.remove(id);
        notifyListeners();
      }
    }
  }

  void limparNotificacoes() {
    if (_disposed) return;
    _sessao++;
    _consultaEmAndamento = null;
    _notificacoes = [];
    _carregadas = false;
    _carregando = false;
    _erro = null;
    _marcandoComoLida.clear();
    _leiturasDuranteConsulta.clear();
    notifyListeners();
  }

  bool _sessaoAtual(int sessao) => !_disposed && sessao == _sessao;

  Future<String> _obterToken() async {
    final token = await _authService.obterToken();
    if (token == null || token.trim().isEmpty) {
      throw const ApiException(
        'Sua sessão expirou. Faça login novamente.',
        statusCode: 401,
      );
    }
    return token;
  }

  ApiException _erroControlado(Object error, String mensagem) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return const ApiException(
          'Sua sessão expirou. Faça login novamente.',
          statusCode: 401,
        );
      }
      if (error.statusCode == 500) {
        return ApiException(mensagem, statusCode: error.statusCode);
      }
      return error;
    }
    return ApiException(mensagem);
  }

  @override
  void dispose() {
    _disposed = true;
    _sessao++;
    _consultaEmAndamento = null;
    super.dispose();
  }
}

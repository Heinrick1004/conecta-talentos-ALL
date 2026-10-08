import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    this._baseUrl = ApiConfig.baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Future<dynamic> getJson(String path, {String? token}) {
    return _send('GET', path, token: token);
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    return _send('POST', path, body: body, token: token);
  }

  Future<dynamic> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    return _send('PUT', path, body: body, token: token);
  }

  Future<dynamic> deleteJson(String path, {String? token}) {
    return _send('DELETE', path, token: token);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse(
      '${_baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl}$path',
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await (() async {
        final request = http.Request(method, uri)
          ..headers.addAll(headers)
          ..body = body == null ? '' : jsonEncode(body);
        return http.Response.fromStream(await _client.send(request));
      })().timeout(timeout);
      final decodedBody = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(response.statusCode, decodedBody),
          statusCode: response.statusCode,
        );
      }

      return decodedBody;
    } on TimeoutException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique se a API está em execução.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique se a API está em execução.',
      );
    }
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  String _errorMessage(int statusCode, dynamic body) {
    if (statusCode == 401) return 'E-mail ou senha inválidos.';
    if (statusCode == 500) return 'Não foi possível concluir a operação.';

    if (body is Map<String, dynamic>) {
      final message = body['erro'] ?? body['detail'] ?? body['title'];
      if (message is String && message.trim().isNotEmpty) return message;
    }

    if (statusCode == 404) return 'Recurso não encontrado.';
    if (statusCode == 409) {
      return 'Já existe uma conta cadastrada com esses dados.';
    }
    if (statusCode == 400) return 'Verifique os dados informados.';
    return 'Não foi possível concluir a operação.';
  }
}

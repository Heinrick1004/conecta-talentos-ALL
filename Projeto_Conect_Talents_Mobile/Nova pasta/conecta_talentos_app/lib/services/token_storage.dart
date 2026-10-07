import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

abstract interface class SessionStorage {
  Future<void> salvarSessao(AuthResponse response);
  Future<String?> obterToken();
  Future<void> limparSessao();
}

class TokenStorage implements SessionStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> salvarSessao(AuthResponse response) {
    return _storage.write(key: _tokenKey, value: response.token);
  }

  @override
  Future<String?> obterToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> limparSessao() => _storage.delete(key: _tokenKey);
}

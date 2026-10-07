import 'package:flutter/foundation.dart';

/// Dados locais do candidato compartilhados entre Perfil e candidatura.
class UsuarioMock extends ChangeNotifier {
  UsuarioMock._(
    String nome,
    String email,
    String telefone,
    String cidade,
    String uf,
    List<String> habilidades,
  ) : _nome = nome,
      _email = email,
      _telefone = telefone,
      _cidade = cidade,
      _uf = uf,
      _habilidades = List.unmodifiable(habilidades);

  String _nome;
  String _email;
  String _telefone;
  String _cidade;
  String _uf;
  List<String> _habilidades;

  String get nome => _nome;
  String get email => _email;
  String get telefone => _telefone;
  String get cidade => _cidade;
  String get uf => _uf;
  List<String> get habilidades => _habilidades;

  void atualizar({
    required String nome,
    required String email,
    required String telefone,
    required String cidade,
    required String uf,
    required List<String> habilidades,
  }) {
    _nome = nome;
    _email = email;
    _telefone = telefone;
    _cidade = cidade;
    _uf = uf;
    _habilidades = List.unmodifiable(habilidades);
    notifyListeners();
  }
}

final mockUsuario = UsuarioMock._(
  'Guilherme Heinrick',
  'guilherme.heinrick@email.com',
  '(11) 99999-1234',
  'Sorocaba',
  'SP',
  ['C#', '.NET', 'SQL', 'APIs REST', 'Git'],
);

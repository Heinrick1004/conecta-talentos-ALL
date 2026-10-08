import '../services/api_client.dart';

class PerfilModel {
  const PerfilModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    required this.criadoEm,
    this.telefone,
    this.cidade,
    this.uf,
    this.habilidades,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nome = json['nomeCompleto'];
    final email = json['email'];
    if (id is! int ||
        id <= 0 ||
        nome is! String ||
        nome.trim().isEmpty ||
        email is! String ||
        !RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(email.trim())) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return PerfilModel(
      id: id,
      nomeCompleto: nome.trim(),
      email: email.trim(),
      criadoEm: _data(json['criadoEm']),
      telefone: _opcional(json['telefone']),
      cidade: _opcional(json['cidade']),
      uf: _opcional(json['uf']),
      habilidades: _opcional(json['habilidades']),
    );
  }

  final int id;
  final String nomeCompleto;
  final String email;
  final String? telefone;
  final String? cidade;
  final String? uf;
  final String? habilidades;
  final DateTime criadoEm;

  String get primeiroNome {
    final nome = nomeCompleto.trim();
    return nome.isEmpty ? 'Candidato' : nome.split(RegExp(r'\s+')).first;
  }

  List<String> get listaHabilidades => (habilidades ?? '')
      .split(RegExp(r'[;,\r\n]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  String get localidade => [cidade, uf]
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .join(', ');

  static String? _opcional(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final texto = value.trim();
    return texto.isEmpty ? null : texto;
  }

  static DateTime _data(Object? value) {
    if (value is! String) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final partes = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    final data = DateTime.tryParse(value);
    if (partes == null || data == null) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final ano = int.parse(partes.group(1)!);
    final mes = int.parse(partes.group(2)!);
    final dia = int.parse(partes.group(3)!);
    final calendario = DateTime(ano, mes, dia);
    if (calendario.year != ano ||
        calendario.month != mes ||
        calendario.day != dia) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return data;
  }
}

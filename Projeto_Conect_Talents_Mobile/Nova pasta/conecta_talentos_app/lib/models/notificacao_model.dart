import '../services/api_client.dart';

class NotificacaoModel {
  const NotificacaoModel({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    required this.criadoEm,
    required this.candidaturaId,
  });

  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final titulo = json['titulo'];
    final mensagem = json['mensagem'];
    final lida = json['lida'];
    final candidaturaId = json['candidaturaId'];
    if (id is! int ||
        id <= 0 ||
        titulo is! String ||
        titulo.trim().isEmpty ||
        mensagem is! String ||
        mensagem.trim().isEmpty ||
        lida is! bool ||
        candidaturaId is! int ||
        candidaturaId <= 0) {
      throw const ApiException('Resposta inválida do servidor.');
    }

    return NotificacaoModel(
      id: id,
      titulo: titulo.trim(),
      mensagem: mensagem.trim(),
      lida: lida,
      criadoEm: _data(json['criadoEm']),
      candidaturaId: candidaturaId,
    );
  }

  final int id;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime criadoEm;
  final int candidaturaId;

  NotificacaoModel copyWith({bool? lida}) => NotificacaoModel(
    id: id,
    titulo: titulo,
    mensagem: mensagem,
    lida: lida ?? this.lida,
    criadoEm: criadoEm,
    candidaturaId: candidaturaId,
  );

  String get dataFormatada {
    String doisDigitos(int valor) => valor.toString().padLeft(2, '0');
    return '${doisDigitos(criadoEm.day)}/${doisDigitos(criadoEm.month)}/'
        '${criadoEm.year.toString().padLeft(4, '0')} às '
        '${doisDigitos(criadoEm.hour)}:${doisDigitos(criadoEm.minute)}';
  }

  static DateTime _data(Object? value) {
    if (value is! String) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final partes = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-](\d{2}):(\d{2}))?)?$',
    ).firstMatch(value);
    final data = DateTime.tryParse(value);
    if (partes == null || data == null) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    final ano = int.parse(partes.group(1)!);
    final mes = int.parse(partes.group(2)!);
    final dia = int.parse(partes.group(3)!);
    final calendario = DateTime(ano, mes, dia);
    final hora = int.parse(partes.group(4) ?? '0');
    final minuto = int.parse(partes.group(5) ?? '0');
    final segundo = int.parse(partes.group(6) ?? '0');
    final horaFuso = int.parse(partes.group(7) ?? '0');
    final minutoFuso = int.parse(partes.group(8) ?? '0');
    if (calendario.year != ano ||
        calendario.month != mes ||
        calendario.day != dia ||
        hora > 23 ||
        minuto > 59 ||
        segundo > 59 ||
        horaFuso > 23 ||
        minutoFuso > 59) {
      throw const ApiException('Resposta inválida do servidor.');
    }
    return data;
  }
}

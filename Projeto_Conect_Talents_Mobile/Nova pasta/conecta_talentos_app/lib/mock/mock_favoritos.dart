import 'package:flutter/foundation.dart';

import 'mock_vagas.dart';

/// Favoritos temporários mantidos em memória durante a execução do app.
class MockFavoritos extends ChangeNotifier {
  final List<VagaMock> _vagas = [];

  List<VagaMock> get vagas => List.unmodifiable(_vagas);

  bool contem(VagaMock vaga) =>
      _vagas.any((favorita) => _mesmaVaga(favorita, vaga));

  void adicionar(VagaMock vaga) {
    if (contem(vaga)) return;
    _vagas.add(vaga);
    // TODO: remover o fallback quando candidaturas também usarem IDs da API.
    notifyListeners();
  }

  void remover(VagaMock vaga) {
    final index = _vagas.indexWhere((favorita) => _mesmaVaga(favorita, vaga));
    if (index < 0) return;
    _vagas.removeAt(index);
    // TODO: remover o fallback quando candidaturas também usarem IDs da API.
    notifyListeners();
  }

  void alternar(VagaMock vaga) {
    if (contem(vaga)) {
      remover(vaga);
    } else {
      adicionar(vaga);
    }
  }

  bool _mesmaVaga(VagaMock primeira, VagaMock segunda) =>
      primeira.titulo == segunda.titulo && primeira.empresa == segunda.empresa;
}

final mockFavoritos = MockFavoritos();

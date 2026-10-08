import 'package:flutter/foundation.dart';

<<<<<<< ours
<<<<<<< ours
import 'mock_vagas.dart';

/// Favoritos temporários mantidos em memória durante a execução do app.
class MockFavoritos extends ChangeNotifier {
  final List<VagaMock> _vagas = [];

  List<VagaMock> get vagas => List.unmodifiable(_vagas);

  bool contem(VagaMock vaga) =>
      _vagas.any((favorita) => _mesmaVaga(favorita, vaga));

  void adicionar(VagaMock vaga) {
=======
=======
>>>>>>> theirs
import '../models/vaga_model.dart';

/// Favoritos temporários mantidos em memória durante a execução do app.
class MockFavoritos extends ChangeNotifier {
  final List<VagaModel> _vagas = [];

  List<VagaModel> get vagas => List.unmodifiable(_vagas);

  bool contem(VagaModel vaga) =>
      _vagas.any((favorita) => _mesmaVaga(favorita, vaga));

  void adicionar(VagaModel vaga) {
<<<<<<< ours
>>>>>>> theirs
=======
>>>>>>> theirs
    if (contem(vaga)) return;
    _vagas.add(vaga);
    // TODO: remover o fallback quando candidaturas também usarem IDs da API.
    notifyListeners();
  }

<<<<<<< ours
<<<<<<< ours
  void remover(VagaMock vaga) {
=======
  void remover(VagaModel vaga) {
>>>>>>> theirs
=======
  void remover(VagaModel vaga) {
>>>>>>> theirs
    final index = _vagas.indexWhere((favorita) => _mesmaVaga(favorita, vaga));
    if (index < 0) return;
    _vagas.removeAt(index);
    // TODO: remover o fallback quando candidaturas também usarem IDs da API.
    notifyListeners();
  }

<<<<<<< ours
<<<<<<< ours
  void alternar(VagaMock vaga) {
=======
  void alternar(VagaModel vaga) {
>>>>>>> theirs
=======
  void alternar(VagaModel vaga) {
>>>>>>> theirs
    if (contem(vaga)) {
      remover(vaga);
    } else {
      adicionar(vaga);
    }
  }

<<<<<<< ours
<<<<<<< ours
  bool _mesmaVaga(VagaMock primeira, VagaMock segunda) =>
=======
  bool _mesmaVaga(VagaModel primeira, VagaModel segunda) =>
>>>>>>> theirs
=======
  bool _mesmaVaga(VagaModel primeira, VagaModel segunda) =>
>>>>>>> theirs
      primeira.titulo == segunda.titulo && primeira.empresa == segunda.empresa;
}

final mockFavoritos = MockFavoritos();

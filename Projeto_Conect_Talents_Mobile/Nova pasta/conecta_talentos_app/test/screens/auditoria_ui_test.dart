import 'dart:async';

import 'package:conecta_talentos_app/models/auth_models.dart';
import 'package:conecta_talentos_app/models/vaga_model.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/screens/login_screen.dart';
import 'package:conecta_talentos_app/screens/main_navigation_screen.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login pendente não permite deixar Login abaixo da Home', (
    tester,
  ) async {
    final auth = _AuthPendente();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: LoginScreen(authService: auth)),
    );
    await _aguardarInterface(tester);
    await tester.enterText(find.byType(TextField).at(0), 'qa@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'senha-de-teste');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.tap(find.text('Criar conta'));
    await _aguardarInterface(tester);

    auth.concluir();
    await _aguardarInterface(tester);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
    expect(find.byType(LoginScreen, skipOffstage: false), findsNothing);
    expect(auth.logins, 1);
  });

  testWidgets('login pendente ignora acionamentos duplicados', (tester) async {
    final auth = _AuthPendente();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: LoginScreen(authService: auth)),
    );
    await _aguardarInterface(tester);
    await tester.enterText(find.byType(TextField).at(0), 'qa@example.test');
    await tester.enterText(find.byType(TextField).at(1), 'senha-de-teste');
    final entrar = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    entrar.onPressed!();
    entrar.onPressed!();
    await tester.pump();
    final chamadas = auth.logins;
    auth.concluir();
    await _aguardarInterface(tester);
    expect(chamadas, 1);
  });

  for (final favoritaInicial in [false, true]) {
    testWidgets(
      'GET anterior não desfaz ${favoritaInicial ? 'remoção' : 'adição'} de favorito confirmada',
      (tester) async {
        final resposta = Completer<VagaModel>();
        final vaga = _vaga(favoritada: favoritaInicial);
        final vagas = _VagasPendentes(resposta.future);
        final favoritos = _Favoritos();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: DetalhesVagaScreen(
              vaga: vaga,
              authService: _AuthPendente(),
              vagasService: vagas,
              favoritosService: favoritos,
            ),
          ),
        );
        await _aguardarInterface(tester);
        await tester.tap(
          find.byTooltip(
            favoritaInicial
                ? 'Remover dos interesses'
                : 'Adicionar aos interesses',
          ),
        );
        await _aguardarInterface(tester);
        final tooltipFinal = favoritaInicial
            ? 'Adicionar aos interesses'
            : 'Remover dos interesses';
        expect(find.byTooltip(tooltipFinal), findsOneWidget);
        expect(
          favoritaInicial ? favoritos.removidos : favoritos.adicionados,
          [7],
        );

        resposta.complete(vaga);
        await _aguardarInterface(tester);
        expect(find.byTooltip(tooltipFinal), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _aguardarInterface(WidgetTester tester) async {
  await tester.pump();
  for (var frame = 0; frame < 4; frame++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump();
}

VagaModel _vaga({bool favoritada = false}) => VagaModel.fromJson({
  'id': 7,
  'titulo': 'Desenvolvedor Flutter',
  'nomeFantasiaEmpresa': 'Empresa QA',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'modalidade': 'Remoto',
  'descricao': 'Descrição real de teste.',
  'favoritada': favoritada,
});

class _AuthPendente extends AuthService {
  final _resposta = Completer<AuthResponse>();
  int logins = 0;

  void concluir() {
    _resposta.complete(
      const AuthResponse(
        token: 'jwt-teste',
        candidato: CandidatoAuth(
          id: 1,
          nomeCompleto: 'Pessoa QA',
          email: 'qa@example.test',
        ),
      ),
    );
  }

  @override
  Future<AuthResponse> login({required String email, required String senha}) {
    logins++;
    return _resposta.future;
  }

  @override
  Future<String?> obterToken() async => null;
}

class _VagasPendentes extends VagasService {
  _VagasPendentes(this.resposta) : super(authService: _AuthPendente());

  final Future<VagaModel> resposta;

  @override
  Future<VagaModel> obterVaga(int id) => resposta;
}

class _Favoritos extends FavoritosService {
  _Favoritos() : super(authService: _AuthPendente());

  final List<int> adicionados = [];
  final List<int> removidos = [];

  @override
  Future<void> adicionarFavorito(int vagaId) async => adicionados.add(vagaId);

  @override
  Future<void> removerFavorito(int vagaId) async => removidos.add(vagaId);
}

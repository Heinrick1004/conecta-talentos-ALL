import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/screens/meus_interesses_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  testWidgets('Meus interesses mantém o cabeçalho e mostra loading', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<List<VagaMock>>();
    final favoritos = _FakeFavoritosService()..resposta = resposta.future;

    await tester.pumpWidget(_aplicativo(favoritos));

    expect(find.text('Meus interesses'), findsOneWidget);
    expect(find.text('Vagas que você salvou'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete([_vaga()]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Analista mobile'), findsOneWidget);
  });

  testWidgets('Meus interesses mostra os favoritos e recarrega ao voltar', (
    WidgetTester tester,
  ) async {
    final favoritos = _FakeFavoritosService()..vagas = [_vaga()];
    final vagasService = _FakeVagasService()..detalhe = _vaga();

    await tester.pumpWidget(_aplicativo(favoritos, vagasService: vagasService));
    await tester.pumpAndSettle();

    expect(find.text('Analista mobile'), findsOneWidget);
    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.text('Sorocaba, SP'), findsOneWidget);
    expect(find.text('Remoto'), findsOneWidget);

    await tester.tap(find.text('Analista mobile'));
    await tester.pumpAndSettle();
    expect(find.byType(DetalhesVagaScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(favoritos.chamadasListagem, 2);
    expect(find.text('Analista mobile'), findsOneWidget);
  });

  testWidgets('Meus interesses apresenta estado vazio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_aplicativo(_FakeFavoritosService()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma vaga salva ainda'), findsOneWidget);
    expect(
      find.text('Favorite vagas para encontrá-las facilmente depois.'),
      findsOneWidget,
    );
  });

  testWidgets('erro de carregamento permite tentar novamente', (
    WidgetTester tester,
  ) async {
    final favoritos = _FakeFavoritosService()
      ..erro = Exception('API indisponível');

    await tester.pumpWidget(_aplicativo(favoritos));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar seus interesses.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);

    favoritos
      ..erro = null
      ..vagas = [_vaga()];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Analista mobile'), findsOneWidget);
    expect(favoritos.chamadasListagem, 2);
  });

  testWidgets('pull-to-refresh consulta novamente os favoritos', (
    WidgetTester tester,
  ) async {
    final favoritos = _FakeFavoritosService()..vagas = [_vaga()];

    await tester.pumpWidget(_aplicativo(favoritos));
    await tester.pumpAndSettle();
    expect(favoritos.chamadasListagem, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(favoritos.chamadasListagem, 2);
  });

  testWidgets('bookmark real atualiza somente após sucesso do serviço', (
    WidgetTester tester,
  ) async {
    final favoritos = _FakeFavoritosService();
    final vaga = _vaga(favoritada: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetalhesVagaScreen(
          vaga: vaga,
          authService: _FakeAuthService(),
          vagasService: _FakeVagasService()..detalhe = vaga,
          favoritosService: favoritos,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adicionar aos interesses'));
    await tester.pump();

    expect(favoritos.adicoes, [7]);
    expect(find.byTooltip('Remover dos interesses'), findsOneWidget);
    expect(find.text('Vaga adicionada aos interesses'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos interesses'));
    await tester.pump();

    expect(favoritos.remocoes, [7]);
    expect(find.byTooltip('Adicionar aos interesses'), findsOneWidget);
    expect(find.text('Vaga removida dos interesses'), findsOneWidget);
  });

  testWidgets('erro ao favoritar não altera o bookmark e mostra feedback', (
    WidgetTester tester,
  ) async {
    final favoritos = _FakeFavoritosService()
      ..erroFavoritar = const ApiException('Erro de API');
    final vaga = _vaga(favoritada: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetalhesVagaScreen(
          vaga: vaga,
          authService: _FakeAuthService(),
          vagasService: _FakeVagasService()..detalhe = vaga,
          favoritosService: favoritos,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adicionar aos interesses'));
    await tester.pump();

    expect(find.byTooltip('Adicionar aos interesses'), findsOneWidget);
    expect(
      find.text('Não foi possível atualizar seus interesses.'),
      findsOneWidget,
    );
  });
}

Widget _aplicativo(
  _FakeFavoritosService favoritos, {
  VagasService? vagasService,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MeusInteressesScreen(
      authService: _FakeAuthService(),
      favoritosService: favoritos,
      vagasService: vagasService ?? _FakeVagasService(),
    ),
  );
}

VagaMock _vaga({bool favoritada = true}) {
  return VagaMock(
    id: 7,
    titulo: 'Analista mobile',
    empresa: 'Empresa Teste',
    local: 'Sorocaba, SP',
    modalidade: 'Remoto',
    sigla: 'ET',
    iconeModalidade: Icons.home_outlined,
    descricao: 'Vaga teste',
    requisitos: const ['Flutter'],
    indiceDestaque: 0,
    favoritada: favoritada,
  );
}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
    : super(
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );

  @override
  Future<String?> obterToken() async => 'jwt-teste';
}

class _FakeFavoritosService extends FavoritosService {
  _FakeFavoritosService() : super(authService: _FakeAuthService());

  List<VagaMock> vagas = [];
  Future<List<VagaMock>>? resposta;
  Exception? erro;
  Exception? erroFavoritar;
  int chamadasListagem = 0;
  final List<int> adicoes = [];
  final List<int> remocoes = [];

  @override
  Future<List<VagaMock>> listarFavoritos() async {
    chamadasListagem++;
    final respostaPendente = resposta;
    if (respostaPendente != null) return respostaPendente;
    final erroAtual = erro;
    if (erroAtual != null) throw erroAtual;
    return vagas;
  }

  @override
  Future<void> adicionarFavorito(int vagaId) async {
    adicoes.add(vagaId);
    final erroAtual = erroFavoritar;
    if (erroAtual != null) throw erroAtual;
  }

  @override
  Future<void> removerFavorito(int vagaId) async {
    remocoes.add(vagaId);
  }
}

class _FakeVagasService extends VagasService {
  _FakeVagasService() : super(authService: _FakeAuthService());

  VagaMock? detalhe;

  @override
  Future<VagaMock> obterVaga(int id) async => detalhe!;
}

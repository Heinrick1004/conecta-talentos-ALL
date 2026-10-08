import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/auth_models.dart';
import 'package:conecta_talentos_app/screens/candidaturas_screen.dart';
import 'package:conecta_talentos_app/screens/capacitacao_screen.dart';
import 'package:conecta_talentos_app/screens/home_screen.dart';
import 'package:conecta_talentos_app/screens/main_navigation_screen.dart';
import 'package:conecta_talentos_app/screens/perfil_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';
import 'package:conecta_talentos_app/services/token_storage.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:conecta_talentos_app/widgets/app_header.dart';

void main() {
  testWidgets(
    'uma instância e um GET compartilham o perfil entre todas as abas',
    (tester) async {
      _configurarTela(tester);
      final servidor = _ServidorPerfil();
      final services = _Services(servidor);
      await tester.pumpWidget(_app(services));
      await _aguardarInterface(tester);

      _verificarServicoCompartilhado(tester, services.perfilService);
      _verificarHeaders(tester, 'João da Silva', 'J');
      expect(servidor.consultasPerfil, 1);
      expect(servidor.consultasVagas, 1);
      expect(find.text('Olá, João 👋'), findsOneWidget);
      expect(find.text('Desenvolvedor .NET'), findsOneWidget);

      await tester.tap(find.text('Candidaturas'));
      await _aguardarInterface(tester);
      expect(find.text('Minhas candidaturas'), findsOneWidget);
      expect(_headerVisivel(tester).userName, 'João da Silva');
      await tester.tap(find.text('Perfil'));
      await _aguardarInterface(tester);
      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('joao@example.com'), findsOneWidget);
      expect(servidor.consultasPerfil, 1);
      expect(servidor.consultasVagas, 1);
      expect(tester.takeException(), isNull);

      await _encerrar(tester, services);
    },
  );

  testWidgets('PUT propaga nome e inicial sem relogar nem recarregar vagas', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorPerfil();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    await tester.runAsync(() async {
      await services.perfilService.atualizarPerfil(
        nomeCompleto: ' Ana Maria Lima ',
        telefone: ' (15) 98888-8888 ',
        cidade: ' Campinas ',
        uf: ' sp ',
        habilidades: 'Flutter, SQL',
      );
    });
    await _aguardarInterface(tester);

    expect(find.text('Olá, Ana 👋'), findsOneWidget);
    expect(find.text('Olá, João 👋'), findsNothing);
    _verificarServicoCompartilhado(tester, services.perfilService);
    _verificarHeaders(tester, 'Ana Maria Lima', 'A');
    expect(servidor.consultasVagas, 1);
    expect(servidor.consultasPerfil, 1);
    expect(servidor.atualizacoesPerfil, 1);
    expect(
      servidor.pedidos.any((path) => path.startsWith('/api/auth/')),
      isFalse,
    );

    await tester.tap(find.text('Candidaturas'));
    await _aguardarInterface(tester);
    expect(_headerVisivel(tester).userName, 'Ana Maria Lima');
    await tester.tap(find.text('Capacitação'));
    await _aguardarInterface(tester);
    expect(_headerVisivel(tester).userName, 'Ana Maria Lima');
    await tester.tap(find.text('Perfil'));
    await _aguardarInterface(tester);
    expect(find.text('Ana Maria Lima'), findsOneWidget);
    expect(find.text('Campinas, SP'), findsOneWidget);
    expect(servidor.consultasVagas, 1);
    expect(servidor.consultasPerfil, 1);
    expect(tester.takeException(), isNull);

    await _encerrar(tester, services);
  });

  testWidgets('perfil pendente usa Candidato e permite carregar vagas', (
    tester,
  ) async {
    _configurarTela(tester);
    final resposta = Completer<http.Response>();
    final servidor = _ServidorPerfil()..respostaPerfil = resposta.future;
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    expect(services.perfilService.carregando, isTrue);
    expect(find.text('Olá, Candidato 👋'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);
    _verificarHeaders(tester, 'Candidato', 'C');
    expect(servidor.consultasPerfil, 1);
    expect(servidor.consultasVagas, 1);

    resposta.complete(servidor.respostaAtual());
    await _aguardarInterface(tester);
    expect(find.text('Olá, João 👋'), findsOneWidget);
    _verificarHeaders(tester, 'João da Silva', 'J');
    expect(servidor.consultasVagas, 1);
    expect(tester.takeException(), isNull);

    await _encerrar(tester, services);
  });

  testWidgets('falha do perfil mantém nome neutro e não bloqueia a Home', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorPerfil()..falharPerfil = true;
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    expect(services.perfilService.erro, isNotNull);
    expect(services.perfilService.carregando, isFalse);
    expect(find.text('Olá, Candidato 👋'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);
    _verificarHeaders(tester, 'Candidato', 'C');

    await tester.tap(find.text('Perfil'));
    await _aguardarInterface(tester);
    expect(find.text('Não foi possível carregar seu perfil.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await _aguardarInterface(tester);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);
    expect(servidor.consultasVagas, 1);
    expect(tester.takeException(), isNull);

    await _encerrar(tester, services);
  });

  testWidgets('MainNavigation cria um único perfil quando não há injeção', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorPerfil();
    final services = _Services(servidor, token: null);
    await tester.pumpWidget(_app(services, injetarPerfil: false));
    await _aguardarInterface(tester);

    final perfilService = tester
        .widget<HomeScreen>(find.byType(HomeScreen))
        .perfilService!;
    expect(perfilService, isNot(same(services.perfilService)));
    _verificarServicoCompartilhado(tester, perfilService);
    _verificarHeaders(tester, 'Candidato', 'C');
    expect(perfilService.erro, 'Sua sessão expirou. Faça login novamente.');
    expect(servidor.pedidos, isEmpty);
    expect(tester.takeException(), isNull);

    await _encerrar(tester, services);
  });
}

void _verificarServicoCompartilhado(
  WidgetTester tester,
  PerfilService perfilService,
) {
  expect(
    tester
        .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
        .perfilService,
    same(perfilService),
  );
  expect(
    tester
        .widget<CandidaturasScreen>(
          find.byType(CandidaturasScreen, skipOffstage: false),
        )
        .perfilService,
    same(perfilService),
  );
  expect(
    tester
        .widget<PerfilScreen>(find.byType(PerfilScreen, skipOffstage: false))
        .perfilService,
    same(perfilService),
  );
  expect(
    tester
        .widget<CapacitacaoScreen>(
          find.byType(CapacitacaoScreen, skipOffstage: false),
        )
        .perfilService,
    same(perfilService),
  );
  final headers = tester.widgetList<AppHeader>(
    find.byType(AppHeader, skipOffstage: false),
  );
  expect(headers, hasLength(4));
  for (final header in headers) {
    expect(header.perfilService, same(perfilService));
  }
}

void _verificarHeaders(WidgetTester tester, String nome, String inicial) {
  final headers = find.byType(AppHeader, skipOffstage: false);
  for (final header in tester.widgetList<AppHeader>(headers)) {
    expect(header.userName, nome);
    expect(header.hasUnreadNotifications, isFalse);
  }
  expect(
    find.descendant(
      of: headers,
      matching: find.text(inicial, skipOffstage: false),
      skipOffstage: false,
    ),
    findsNWidgets(4),
  );
  expect(find.text('Olá, Guilherme 👋', skipOffstage: false), findsNothing);
  expect(find.text('Mariana Costa', skipOffstage: false), findsNothing);
}

AppHeader _headerVisivel(WidgetTester tester) =>
    tester.widget<AppHeader>(find.byType(AppHeader));

Future<void> _aguardarInterface(WidgetTester tester) async {
  // A aba Capacitação mantém uma animação contínua no IndexedStack.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

Future<void> _encerrar(WidgetTester tester, _Services services) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  services.perfilService.dispose();
}

void _configurarTela(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MaterialApp _app(_Services services, {bool injetarPerfil = true}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: MainNavigationScreen(
        authService: services.authService,
        vagasService: services.vagasService,
        favoritosService: services.favoritosService,
        candidaturasService: services.candidaturasService,
        perfilService: injetarPerfil ? services.perfilService : null,
      ),
    );

class _Services {
  _Services(_ServidorPerfil servidor, {String? token = 'jwt-teste'}) {
    final apiClient = ApiClient(client: MockClient(servidor.responder));
    authService = AuthService(
      apiClient: apiClient,
      tokenStorage: _MemorySessionStorage(token),
    );
    perfilService = PerfilService(
      authService: authService,
      apiClient: apiClient,
    );
    vagasService = VagasService(authService: authService, apiClient: apiClient);
    favoritosService = FavoritosService(
      authService: authService,
      apiClient: apiClient,
    );
    candidaturasService = CandidaturasService(
      authService: authService,
      apiClient: apiClient,
    );
  }

  late final AuthService authService;
  late final PerfilService perfilService;
  late final VagasService vagasService;
  late final FavoritosService favoritosService;
  late final CandidaturasService candidaturasService;
}

class _ServidorPerfil {
  Map<String, dynamic> perfil = {
    'id': 1008,
    'nomeCompleto': 'João da Silva',
    'email': 'joao@example.com',
    'telefone': '(15) 99999-9999',
    'cidade': 'Sorocaba',
    'uf': 'SP',
    'habilidades': 'C#; Flutter; SQL',
    'criadoEm': '2026-10-07T20:00:00',
  };
  Future<http.Response>? respostaPerfil;
  bool falharPerfil = false;
  int consultasPerfil = 0;
  int consultasVagas = 0;
  int atualizacoesPerfil = 0;
  final List<String> pedidos = [];

  Future<http.Response> responder(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer jwt-teste');
    pedidos.add(request.url.path);
    switch ((request.method, request.url.path)) {
      case ('GET', '/api/candidato/perfil'):
        consultasPerfil++;
        if (respostaPerfil != null) return respostaPerfil!;
        if (falharPerfil) return http.Response('{}', 500);
        return respostaAtual();
      case ('PUT', '/api/candidato/perfil'):
        atualizacoesPerfil++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {
          'nomeCompleto',
          'telefone',
          'cidade',
          'uf',
          'habilidades',
        });
        perfil = {...perfil, ...body};
        return respostaAtual();
      case ('GET', '/api/candidato/vagas'):
        consultasVagas++;
        return _resposta([
          {
            'id': 7,
            'titulo': 'Desenvolvedor .NET',
            'nomeFantasiaEmpresa': 'Empresa Real',
            'cidade': 'Sorocaba',
            'uf': 'SP',
            'modalidade': 'Hibrido',
          },
        ]);
      case ('GET', '/api/candidato/candidaturas'):
      case ('GET', '/api/candidato/favoritos'):
        return _resposta([]);
      default:
        fail('Requisição inesperada: ${request.method} ${request.url.path}');
    }
  }

  http.Response respostaAtual() => _resposta(perfil);

  http.Response _resposta(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage(this.token);

  String? token;

  @override
  Future<void> limparSessao() async {
    token = null;
  }

  @override
  Future<String?> obterToken() async => token;

  @override
  Future<void> salvarSessao(AuthResponse response) async {
    token = response.token;
  }
}

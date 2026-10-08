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
import 'package:conecta_talentos_app/screens/login_screen.dart';
import 'package:conecta_talentos_app/screens/main_navigation_screen.dart';
import 'package:conecta_talentos_app/screens/notificacoes_screen.dart';
import 'package:conecta_talentos_app/screens/perfil_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/notificacoes_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';
import 'package:conecta_talentos_app/services/token_storage.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:conecta_talentos_app/widgets/app_header.dart';

void main() {
  testWidgets('indicador real só desaparece depois da última não lida', (
    tester,
  ) async {
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await services.notificacoes.carregarNotificacoes();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppHeader(notificacoesService: services.notificacoes),
        ),
      ),
    );

    expect(services.notificacoes.naoLidas, 2);
    expect(_indicador(), findsOneWidget);

    await services.notificacoes.marcarComoLida(15);
    await tester.pump();
    expect(services.notificacoes.naoLidas, 1);
    expect(_indicador(), findsOneWidget);

    await services.notificacoes.marcarComoLida(16);
    await tester.pump();
    expect(services.notificacoes.naoLidas, 0);
    expect(_indicador(), findsNothing);
    expect(servidor.idsMarcados, [15, 16]);
    await _encerrar(tester, services);
  });

  testWidgets('serviço tem prioridade e booleano funciona como fallback', (
    tester,
  ) async {
    final servidor = _ServidorNotificacoes()..notificacoes = [];
    final services = _Services(servidor);
    await services.notificacoes.carregarNotificacoes();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppHeader(hasUnreadNotifications: true)),
      ),
    );
    expect(_indicador(), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppHeader(
            hasUnreadNotifications: true,
            notificacoesService: services.notificacoes,
          ),
        ),
      ),
    );
    expect(_indicador(), findsNothing);
    await _encerrar(tester, services);
  });

  testWidgets('quatro abas usam uma única instância e GET inicial', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    _verificarServiceCompartilhado(tester, services.notificacoes);
    expect(servidor.consultasNotificacoes, 1);
    expect(servidor.consultasPerfil, 1);
    expect(servidor.consultasVagas, 1);
    expect(_indicador(skipOffstage: false), findsNWidgets(4));

    await services.notificacoes.marcarComoLida(15);
    await services.notificacoes.marcarComoLida(16);
    await _aguardarInterface(tester);
    expect(_indicador(skipOffstage: false), findsNothing);
    expect(servidor.consultasNotificacoes, 1);
    expect(find.text('Olá, João 👋'), findsOneWidget);
    await _encerrar(tester, services);
  });

  testWidgets('Main cria uma única instância quando não há injeção', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor, token: null);
    await tester.pumpWidget(_app(services, injetarNotificacoes: false));
    await _aguardarInterface(tester);

    final service = tester
        .widget<HomeScreen>(find.byType(HomeScreen))
        .notificacoesService!;
    expect(service, isNot(same(services.notificacoes)));
    _verificarServiceCompartilhado(tester, service);
    expect(service.erro, 'Sua sessão expirou. Faça login novamente.');
    expect(servidor.pedidos, isEmpty);
    expect(tester.takeException(), isNull);
    await _encerrar(tester, services);
  });

  testWidgets('sino das quatro abas abre a mesma tela e busca novidades', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    for (final aba in ['Home', 'Candidaturas', 'Capacitação', 'Perfil']) {
      if (aba != 'Home') {
        await tester.tap(find.text(aba).last);
        await _aguardarInterface(tester);
      }
      final consultasAntes = servidor.consultasNotificacoes;
      await tester.tap(find.byTooltip('Notificações'));
      await _aguardarInterface(tester);

      final tela = tester.widget<NotificacoesScreen>(
        find.byType(NotificacoesScreen),
      );
      expect(tela.notificacoesService, same(services.notificacoes));
      expect(tela.perfilService, same(services.perfil));
      expect(servidor.consultasNotificacoes, consultasAntes + 1);
      expect(find.text('Sua candidatura foi aceita'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await _aguardarInterface(tester);
      expect(find.byType(NotificacoesScreen), findsNothing);
    }
    expect(tester.takeException(), isNull);
    await _encerrar(tester, services);
  });

  testWidgets('toques repetidos no sino abrem só uma rota', (tester) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);
    final sino = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Notificações',
      ),
    );
    sino.onPressed!();
    sino.onPressed!();
    await _aguardarInterface(tester);

    expect(
      find.byType(NotificacoesScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(servidor.consultasNotificacoes, 2);
    await _encerrar(tester, services);
  });

  testWidgets('menu Perfil abre notificações e ação retorna a Candidaturas', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);
    await tester.tap(find.text('Perfil'));
    await _aguardarInterface(tester);

    await tester.ensureVisible(find.text('Notificações'));
    await _aguardarInterface(tester);
    await tester.tap(find.text('Notificações'));
    await _aguardarInterface(tester);
    expect(
      tester
          .widget<NotificacoesScreen>(find.byType(NotificacoesScreen))
          .notificacoesService,
      same(services.notificacoes),
    );

    await tester.tap(find.text('Ver candidaturas').first);
    await _aguardarInterface(tester);
    expect(find.byType(NotificacoesScreen), findsNothing);
    expect(find.byType(CandidaturasScreen), findsOneWidget);
    expect(find.text('Minhas candidaturas'), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(servidor.idsMarcados, isEmpty);
    expect(tester.takeException(), isNull);
    await _encerrar(tester, services);
  });

  testWidgets('GET pendente das notificações não impede Home ou perfil', (
    tester,
  ) async {
    _configurarTela(tester);
    final resposta = Completer<http.Response>();
    final servidor = _ServidorNotificacoes()..respostaNotificacoes = resposta;
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    expect(services.notificacoes.carregando, isTrue);
    expect(find.text('Olá, João 👋'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);
    expect(servidor.consultasPerfil, 1);
    expect(servidor.consultasVagas, 1);
    resposta.complete(servidor.respostaAtual());
    await _aguardarInterface(tester);
    expect(_indicador(), findsOneWidget);
    await _encerrar(tester, services);
  });

  testWidgets('erro das notificações não bloqueia vagas e perfil', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes()..statusNotificacoes = 500;
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);

    expect(services.notificacoes.erro, isNotNull);
    expect(find.text('Olá, João 👋'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);
    expect(_indicador(), findsNothing);
    await tester.tap(find.text('Perfil'));
    await _aguardarInterface(tester);
    expect(find.text('João da Silva'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _encerrar(tester, services);
  });

  testWidgets('logout cancelado conserva notificações e confirmado limpa', (
    tester,
  ) async {
    _configurarTela(tester);
    final servidor = _ServidorNotificacoes();
    final services = _Services(servidor);
    await tester.pumpWidget(_app(services));
    await _aguardarInterface(tester);
    await tester.tap(find.text('Perfil'));
    await _aguardarInterface(tester);
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await _aguardarInterface(tester);
    await tester.tap(find.text('Sair da conta'));
    await _aguardarInterface(tester);
    await tester.tap(find.text('Cancelar'));
    await _aguardarInterface(tester);

    expect(services.notificacoes.naoLidas, 2);
    expect(services.storage.token, 'jwt-teste');
    await tester.tap(find.text('Sair da conta'));
    await _aguardarInterface(tester);
    await tester.tap(find.text('Sair'));
    await _aguardarInterface(tester);

    expect(services.storage.token, isNull);
    expect(services.perfil.perfil, isNull);
    expect(services.notificacoes.notificacoes, isEmpty);
    expect(services.notificacoes.naoLidas, 0);
    expect(services.notificacoes.carregando, isFalse);
    expect(services.notificacoes.erro, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await _encerrar(tester, services);
  });
}

Finder _indicador({bool skipOffstage = true}) => find.byKey(
  const Key('notifications-unread-indicator'),
  skipOffstage: skipOffstage,
);

void _verificarServiceCompartilhado(
  WidgetTester tester,
  NotificacoesService service,
) {
  expect(
    tester
        .widget<HomeScreen>(find.byType(HomeScreen, skipOffstage: false))
        .notificacoesService,
    same(service),
  );
  expect(
    tester
        .widget<CandidaturasScreen>(
          find.byType(CandidaturasScreen, skipOffstage: false),
        )
        .notificacoesService,
    same(service),
  );
  expect(
    tester
        .widget<CapacitacaoScreen>(
          find.byType(CapacitacaoScreen, skipOffstage: false),
        )
        .notificacoesService,
    same(service),
  );
  expect(
    tester
        .widget<PerfilScreen>(find.byType(PerfilScreen, skipOffstage: false))
        .notificacoesService,
    same(service),
  );
  final headers = tester.widgetList<AppHeader>(
    find.byType(AppHeader, skipOffstage: false),
  );
  expect(headers, hasLength(4));
  for (final header in headers) {
    expect(header.notificacoesService, same(service));
    expect(header.onNotificationsTap, isNotNull);
  }
}

Future<void> _aguardarInterface(WidgetTester tester) async {
  // Capacitação mantém uma animação contínua enquanto as abas estão montadas.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

Future<void> _encerrar(WidgetTester tester, _Services services) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  services.perfil.dispose();
  services.notificacoes.dispose();
}

void _configurarTela(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(_Services services, {bool injetarNotificacoes = true}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: MainNavigationScreen(
        authService: services.auth,
        perfilService: services.perfil,
        notificacoesService: injetarNotificacoes ? services.notificacoes : null,
        vagasService: services.vagas,
        favoritosService: services.favoritos,
        candidaturasService: services.candidaturas,
      ),
    );

class _Services {
  _Services(_ServidorNotificacoes servidor, {String? token = 'jwt-teste'}) {
    final client = ApiClient(client: MockClient(servidor.responder));
    storage = _MemorySessionStorage(token);
    auth = AuthService(apiClient: client, tokenStorage: storage);
    perfil = PerfilService(authService: auth, apiClient: client);
    notificacoes = NotificacoesService(authService: auth, apiClient: client);
    vagas = VagasService(authService: auth, apiClient: client);
    favoritos = FavoritosService(authService: auth, apiClient: client);
    candidaturas = CandidaturasService(authService: auth, apiClient: client);
  }

  late final _MemorySessionStorage storage;
  late final AuthService auth;
  late final PerfilService perfil;
  late final NotificacoesService notificacoes;
  late final VagasService vagas;
  late final FavoritosService favoritos;
  late final CandidaturasService candidaturas;
}

class _ServidorNotificacoes {
  List<Map<String, dynamic>> notificacoes = [
    {
      'id': 15,
      'titulo': 'Sua candidatura foi aceita',
      'mensagem': 'A candidatura para a vaga Desenvolvedor .NET foi aceita.',
      'lida': false,
      'criadoEm': '2026-10-08T10:30:00',
      'candidaturaId': 110,
    },
    {
      'id': 16,
      'titulo': 'Sua candidatura foi recusada',
      'mensagem': 'A candidatura para a vaga Analista foi recusada.',
      'lida': false,
      'criadoEm': '2026-10-07T20:30:00',
      'candidaturaId': 111,
    },
  ];
  int consultasNotificacoes = 0;
  int consultasPerfil = 0;
  int consultasVagas = 0;
  int statusNotificacoes = 200;
  Completer<http.Response>? respostaNotificacoes;
  final List<int> idsMarcados = [];
  final List<String> pedidos = [];

  Future<http.Response> responder(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer jwt-teste');
    pedidos.add(request.url.path);
    switch ((request.method, request.url.path)) {
      case ('GET', '/api/candidato/notificacoes'):
        consultasNotificacoes++;
        if (respostaNotificacoes != null) {
          return respostaNotificacoes!.future;
        }
        if (statusNotificacoes != 200) {
          return _resposta({
            'erro': 'Servidor indisponível',
          }, statusNotificacoes);
        }
        return respostaAtual();
      case ('GET', '/api/candidato/perfil'):
        consultasPerfil++;
        return _resposta({
          'id': 1008,
          'nomeCompleto': 'João da Silva',
          'email': 'joao@example.test',
          'cidade': 'Sorocaba',
          'uf': 'SP',
          'habilidades': 'Flutter; SQL',
          'criadoEm': '2026-10-07T20:00:00',
        });
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
        final match = RegExp(r'^/api/candidato/notificacoes/(\d+)/marcar-lida$')
            .firstMatch(request.url.path);
        if (request.method == 'PATCH' && match != null) {
          expect(request.body, isEmpty);
          final id = int.parse(match.group(1)!);
          idsMarcados.add(id);
          notificacoes = [
            for (final item in notificacoes)
              if (item['id'] == id) {...item, 'lida': true} else item,
          ];
          return http.Response('', 204);
        }
        fail('Requisição inesperada: ${request.method} ${request.url.path}');
    }
  }

  http.Response respostaAtual() => _resposta(notificacoes);

  http.Response _resposta(Object body, [int statusCode = 200]) => http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage(this.token);

  String? token;

  @override
  Future<void> limparSessao() async => token = null;

  @override
  Future<String?> obterToken() async => token;

  @override
  Future<void> salvarSessao(AuthResponse response) async =>
      token = response.token;
}

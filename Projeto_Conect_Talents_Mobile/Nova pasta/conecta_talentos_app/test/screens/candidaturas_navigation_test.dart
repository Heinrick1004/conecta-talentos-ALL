import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/auth_models.dart';
import 'package:conecta_talentos_app/screens/candidatura_confirmacao_screen.dart';
import 'package:conecta_talentos_app/screens/candidaturas_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_candidatura_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/screens/home_screen.dart';
import 'package:conecta_talentos_app/screens/main_navigation_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/token_storage.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  testWidgets(
    'Home confirma pela API, recarrega a aba e limpa a pilha de navegação',
    (tester) async {
      _configurarTela(tester);
      final servidor = _ServidorCandidaturas();
      final services = _Services(servidor);
      await tester.pumpWidget(_app(services));
      await _aguardarInterface(tester);

      final home = tester.widget<HomeScreen>(find.byType(HomeScreen));
      expect(home.authService, same(services.authService));
      expect(home.vagasService, same(services.vagasService));
      expect(home.favoritosService, same(services.favoritosService));
      expect(home.candidaturasService, same(services.candidaturasService));
      final consultasAntes = servidor.consultasCandidaturas;

      await _candidatarPelaHome(tester, services);

      expect(servidor.corposPost, [
        {'vagaId': 7},
      ]);
      expect(servidor.status, 'Pendente');
      expect(servidor.consultasCandidaturas, greaterThan(consultasAntes));
      expect(find.text('Minhas candidaturas'), findsOneWidget);
      expect(find.text('Todas (1)'), findsOneWidget);
      expect(find.text('Em análise (1)'), findsOneWidget);
      expect(find.text('Desenvolvedor .NET'), findsOneWidget);
      expect(find.byType(CandidaturaConfirmacaoScreen), findsNothing);
      expect(find.byType(DetalhesVagaScreen), findsNothing);

      final tela = tester.widget<CandidaturasScreen>(
        find.byType(CandidaturasScreen),
      );
      expect(tela.candidaturasService, same(services.candidaturasService));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
      await tester.binding.handlePopRoute();
      await _aguardarInterface(tester);
      expect(find.text('Minhas candidaturas'), findsOneWidget);
      expect(find.byType(CandidaturaConfirmacaoScreen), findsNothing);
      expect(find.byType(DetalhesVagaScreen), findsNothing);

      await tester.tap(find.text('Desenvolvedor .NET'));
      await _aguardarInterface(tester);
      expect(find.byType(DetalhesCandidaturaScreen), findsOneWidget);
      expect(find.text('Enviada em 07/10/2026'), findsOneWidget);
      await tester.tap(find.text('Ver vaga'));
      await _aguardarInterface(tester);

      expect(servidor.consultasDetalhes, 2);
      expect(find.text('Descrição completa obtida pela API.'), findsOneWidget);
      expect(find.text('Você já se candidatou'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recriar o aplicativo consulta persistência e refresh reflete status da empresa',
    (tester) async {
      _configurarTela(tester);
      final servidor = _ServidorCandidaturas();
      final services = _Services(servidor);
      await tester.pumpWidget(_app(services));
      await _aguardarInterface(tester);
      await _candidatarPelaHome(tester, services);
      final consultasAntesReinicio = servidor.consultasCandidaturas;

      await tester.pumpWidget(const SizedBox.shrink());
      await _aguardarInterface(tester);
      await tester.pumpWidget(_app(services));
      await _aguardarInterface(tester);
      await tester.tap(find.text('Candidaturas'));
      await _aguardarInterface(tester);

      expect(servidor.corposPost, hasLength(1));
      expect(
        servidor.consultasCandidaturas,
        greaterThan(consultasAntesReinicio),
      );
      expect(find.text('Desenvolvedor .NET'), findsOneWidget);
      expect(find.text('Todas (1)'), findsOneWidget);
      expect(find.text('Em análise (1)'), findsOneWidget);

      servidor.status = 'Aceita';
      final consultasAntesRefresh = servidor.consultasCandidaturas;
      await tester.drag(find.byType(ListView), const Offset(0, 450));
      await _aguardarInterface(tester);

      expect(
        servidor.consultasCandidaturas,
        greaterThan(consultasAntesRefresh),
      );
      expect(find.text('Em análise (0)'), findsOneWidget);
      expect(find.text('Selecionado (1)'), findsOneWidget);
      expect(find.text('Selecionado'), findsNWidgets(2));

      servidor.status = 'Recusada';
      await tester.drag(find.byType(ListView), const Offset(0, 450));
      await _aguardarInterface(tester);

      expect(find.text('Selecionado (0)'), findsOneWidget);
      expect(find.text('Rejeitado (1)'), findsOneWidget);
      expect(find.text('Rejeitado'), findsOneWidget);
      expect(servidor.corposPost, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _candidatarPelaHome(
  WidgetTester tester,
  _Services services,
) async {
  final abrirVaga = find.byTooltip('Ver vaga: Desenvolvedor .NET');
  await tester.ensureVisible(abrirVaga);
  await tester.tap(abrirVaga);
  await _aguardarInterface(tester);
  final detalhes = tester.widget<DetalhesVagaScreen>(
    find.byType(DetalhesVagaScreen),
  );
  expect(detalhes.authService, same(services.authService));
  expect(detalhes.vagasService, same(services.vagasService));
  expect(detalhes.favoritosService, same(services.favoritosService));
  expect(detalhes.candidaturasService, same(services.candidaturasService));

  await tester.tap(find.text('Candidatar-se'));
  await _aguardarInterface(tester);
  expect(
    tester
        .widget<CandidaturaConfirmacaoScreen>(
          find.byType(CandidaturaConfirmacaoScreen),
        )
        .candidaturasService,
    same(services.candidaturasService),
  );
  await tester.tap(find.byKey(const Key('confirmar-candidatura')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  expect(find.text('Candidatura enviada!'), findsOneWidget);
  await tester.tap(find.text('Ir para candidaturas'));
  await _aguardarInterface(tester);
}

Future<void> _aguardarInterface(WidgetTester tester) async {
  // As abas mantidas no IndexedStack incluem animações contínuas.
  await tester.pump();
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  await tester.pump();
}

void _configurarTela(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MaterialApp _app(_Services services) => MaterialApp(
  theme: AppTheme.light,
  home: MainNavigationScreen(
    authService: services.authService,
    vagasService: services.vagasService,
    favoritosService: services.favoritosService,
    candidaturasService: services.candidaturasService,
  ),
);

class _Services {
  _Services(_ServidorCandidaturas servidor) {
    final apiClient = ApiClient(client: MockClient(servidor.responder));
    authService = AuthService(
      apiClient: apiClient,
      tokenStorage: _MemorySessionStorage(),
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
  late final VagasService vagasService;
  late final FavoritosService favoritosService;
  late final CandidaturasService candidaturasService;
}

class _ServidorCandidaturas {
  String? status;
  int consultasCandidaturas = 0;
  int consultasDetalhes = 0;
  final List<Map<String, dynamic>> corposPost = [];

  Future<http.Response> responder(http.Request request) async {
    expect(request.headers['authorization'], 'Bearer jwt-teste');
    switch ((request.method, request.url.path)) {
      case ('GET', '/api/candidato/perfil'):
        return _resposta({
          'id': 1,
          'nomeCompleto': 'Candidato Teste',
          'email': 'candidato@example.test',
          'telefone': null,
          'cidade': null,
          'uf': null,
          'habilidades': null,
          'criadoEm': '2026-10-07T09:00:00',
        });
      case ('GET', '/api/candidato/vagas'):
        return _resposta([_vaga()]);
      case ('GET', '/api/candidato/vagas/7'):
        consultasDetalhes++;
        return _resposta(_vaga());
      case ('GET', '/api/candidato/candidaturas'):
        consultasCandidaturas++;
        return _resposta([if (status != null) _candidatura()]);
      case ('POST', '/api/candidato/candidaturas'):
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'vagaId': 7});
        corposPost.add(body);
        if (status != null) {
          return _resposta({'erro': 'Você já se candidatou a esta vaga'}, 409);
        }
        status = 'Pendente';
        return _resposta(_candidatura(), 201);
      default:
        fail('Requisição inesperada: ${request.method} ${request.url.path}');
    }
  }

  Map<String, dynamic> _vaga() => {
    'id': 7,
    'titulo': 'Desenvolvedor .NET',
    'nomeFantasiaEmpresa': 'Empresa Real',
    'cidade': 'Sorocaba',
    'uf': 'SP',
    'modalidade': 'Hibrido',
    'descricao': 'Descrição completa obtida pela API.',
    'requisitos': '.NET; API REST',
    'jaCandidatado': status != null,
    'favoritada': false,
  };

  Map<String, dynamic> _candidatura() => {
    'id': 10,
    'status': status,
    'dataCandidatura': '2026-10-07T09:00:00',
    'atualizadoEm': '2026-10-07T10:00:00',
    'vaga': {
      'id': 7,
      'titulo': 'Desenvolvedor .NET',
      'nomeFantasiaEmpresa': 'Empresa Real',
      'cidade': 'Sorocaba',
      'uf': 'SP',
      'modalidade': 'Hibrido',
    },
  };

  http.Response _resposta(Object body, [int statusCode = 200]) => http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

class _MemorySessionStorage implements SessionStorage {
  String? token = 'jwt-teste';

  @override
  Future<void> limparSessao() async => token = null;

  @override
  Future<String?> obterToken() async => token;

  @override
  Future<void> salvarSessao(AuthResponse response) async =>
      token = response.token;
}

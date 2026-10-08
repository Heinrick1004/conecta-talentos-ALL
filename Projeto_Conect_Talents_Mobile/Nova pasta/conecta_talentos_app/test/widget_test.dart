import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/main.dart';
import 'package:conecta_talentos_app/mock/mock_favoritos.dart';
import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/screens/cadastro_screen.dart';
import 'package:conecta_talentos_app/screens/candidaturas_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_candidatura_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/screens/login_screen.dart';
import 'package:conecta_talentos_app/screens/meus_interesses_screen.dart';
import 'package:conecta_talentos_app/screens/main_navigation_screen.dart';
import 'package:conecta_talentos_app/models/auth_models.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/token_storage.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_colors.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  test('sessão rejeita e apaga token expirado ou malformado', () async {
    final storage = _MemorySessionStorage()
      ..token = 'header.${_jwtPayload({'exp': 1})}.signature';
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      tokenStorage: storage,
    );

    expect(await authService.possuiSessaoValida(), isFalse);
    expect(storage.token, isNull);

    storage.token = 'token-malformado';
    expect(await authService.possuiSessaoValida(), isFalse);
    expect(storage.token, isNull);
  });

  test('sessão restaura token com expiração futura', () async {
    final exp =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    final storage = _MemorySessionStorage()
      ..token = 'header.${_jwtPayload({'exp': exp})}.signature';
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
      tokenStorage: storage,
    );

    expect(await authService.possuiSessaoValida(), isTrue);
    expect(storage.token, isNotNull);
  });

  test('login chama endpoint candidato e persiste somente o JWT', () async {
    final storage = _MemorySessionStorage();
    Map<String, dynamic>? requestBody;
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/candidato/login');
          expect(request.headers['content-type'], 'application/json');
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'header.payload.signature',
              'candidato': {
                'id': 12,
                'nomeCompleto': 'Candidato Teste',
                'email': 'teste@example.com',
              },
            }),
            200,
          );
        }),
      ),
      tokenStorage: storage,
    );

    final result = await authService.login(
      email: 'teste@example.com',
      senha: 'senha-secreta',
    );

    expect(requestBody, {
      'email': 'teste@example.com',
      'senha': 'senha-secreta',
    });
    expect(result.candidato.id, 12);
    expect(storage.token, 'header.payload.signature');
  });

  test('cadastro não armazena o token devolvido pela API', () async {
    final storage = _MemorySessionStorage();
    Map<String, dynamic>? requestBody;
    final authService = AuthService(
      apiClient: ApiClient(
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/candidato/registrar');
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'token-de-cadastro',
              'candidato': {
                'id': 13,
                'nomeCompleto': 'Nova Pessoa',
                'email': 'nova@example.com',
              },
            }),
            201,
          );
        }),
      ),
      tokenStorage: storage,
    );

    await authService.registrar(
      nomeCompleto: 'Nova Pessoa',
      email: 'nova@example.com',
      senha: 'senha-secreta',
    );

    expect(requestBody, {
      'nomeCompleto': 'Nova Pessoa',
      'email': 'nova@example.com',
      'senha': 'senha-secreta',
    });
    expect(storage.token, isNull);
  });

  test(
    'favoritos impedem duplicação e permitem remover e adicionar novamente',
    () {
      final vaga = mockVagas.first;

      if (mockFavoritos.contem(vaga)) {
        mockFavoritos.alternar(vaga);
      }

      mockFavoritos.adicionar(vaga);
      mockFavoritos.adicionar(vaga);
      expect(mockFavoritos.vagas, hasLength(1));
      expect(mockFavoritos.contem(vaga), isTrue);

      mockFavoritos.remover(vaga);
      expect(mockFavoritos.vagas, isEmpty);
      mockFavoritos.adicionar(vaga);
      expect(mockFavoritos.vagas, hasLength(1));
      mockFavoritos.remover(vaga);
      expect(mockFavoritos.vagas, isEmpty);
    },
  );

  test('candidaturas mantêm o ID da vaga real sem procurar pelo título', () {
    final candidaturas = _candidaturas();
    expect(candidaturas.map((item) => item.vaga.id), [7, 8, 9, 10]);
    expect(candidaturas[3].vaga.titulo, 'Técnico de Suporte');
    expect(candidaturas[3].vaga.descricao, isEmpty);
    expect(candidaturas[3].vaga.requisitos, isEmpty);
    expect(candidaturas.every((item) => item.vaga.jaCandidatado), isTrue);
  });

  testWidgets('aplicativo inicia em LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authService: _FakeAuthService()));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'ConectaTalentos');
    expect(app.theme!.colorScheme.primary, AppColors.primary);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('login vazio permanece no Login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(authService: _FakeAuthService()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(
      find.text('Informe seu e-mail e senha para continuar.'),
      findsOneWidget,
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
  });

  testWidgets('login preenchido entra na Home', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(authService: _FakeAuthService()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'teste@teste.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Olá, Guilherme 👋'), findsOneWidget);
    expect(find.text('Vagas para você'), findsOneWidget);
  });

  testWidgets('criar conta abre cadastro e retorna ao login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(authService: _FakeAuthService()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.text('Crie sua conta'), findsOneWidget);

    final voltar = find.text('Voltar para o login');
    await tester.ensureVisible(voltar);
    await tester.pump();
    await tester.tap(voltar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('logout pode ser cancelado e limpa a pilha ao sair', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(authService: _FakeAuthService()));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.enterText(find.byType(TextField).at(0), 'teste@teste.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    final botaoSair = find.text('Sair da conta');
    await tester.ensureVisible(botaoSair);
    await tester.pump();
    await tester.tap(botaoSair);
    await tester.pump();

    expect(find.text('Sair da conta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await tester.ensureVisible(botaoSair);
    await tester.pump();
    await tester.tap(botaoSair);
    await tester.pump();
    await tester.tap(find.text('Sair'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Vagas para você'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Vagas para você'), findsNothing);
  });

  testWidgets('favoritos abrem em Meus interesses e atualizam ao remover', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final vaga = mockVagas.first;
    if (mockFavoritos.contem(vaga)) {
      mockFavoritos.alternar(vaga);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MainNavigationScreen(
          authService: _FakeAuthService(),
          vagasService: _MockHomeVagasService(),
          favoritosService: _MockFavoritosService(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final abrirDetalhes = find.byTooltip('Ver vaga: Desenvolvedor .NET');
    await tester.ensureVisible(abrirDetalhes);
    await tester.pump();
    await tester.tap(abrirDetalhes);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.tap(find.byTooltip('Adicionar aos interesses'));
    await tester.pump();
    expect(mockFavoritos.vagas, hasLength(1));
    expect(find.text('Vaga adicionada aos interesses'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos interesses'));
    await tester.pump();
    expect(mockFavoritos.vagas, isEmpty);
    await tester.tap(find.byTooltip('Adicionar aos interesses'));
    await tester.pump();
    expect(mockFavoritos.vagas, hasLength(1));

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Perfil'));
    await tester.pump();

    final meusInteresses = find.text('Meus interesses');
    await tester.ensureVisible(meusInteresses);
    await tester.pump();
    await tester.tap(meusInteresses);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MeusInteressesScreen), findsOneWidget);
    expect(find.text('Vagas que você salvou'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsOneWidget);

    await tester.tap(find.text('Desenvolvedor .NET').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byTooltip('Remover dos interesses'));
    await tester.pump();

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MeusInteressesScreen), findsOneWidget);
    expect(find.text('Nenhuma vaga salva ainda'), findsOneWidget);
    expect(find.text('Desenvolvedor .NET'), findsNothing);
  });

  testWidgets(
    'card de candidatura abre detalhes e Ver vaga impede candidatura duplicada',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final vagasService = _CandidaturaVagasService();
      await tester.pumpWidget(_appCandidaturas(vagasService: vagasService));
      await tester.pumpAndSettle();

      final candidatura = find.text('Analista de Sistemas');
      await tester.ensureVisible(candidatura);
      await tester.pumpAndSettle();
      await tester.tap(candidatura);
      await tester.pumpAndSettle();

      expect(find.byType(DetalhesCandidaturaScreen), findsOneWidget);
      expect(find.text('Detalhes da candidatura'), findsOneWidget);
      expect(find.text('Selecionado'), findsNWidgets(2));
      expect(find.text('Etapas do processo'), findsOneWidget);
      expect(find.text('Em análise'), findsOneWidget);
      expect(find.text('Proposta'), findsNothing);
      expect(find.text('Entrevista'), findsNothing);

      await tester.tap(find.text('Ver vaga'));
      await tester.pumpAndSettle();

      expect(find.byType(DetalhesVagaScreen), findsOneWidget);
      expect(find.text('Analista de Sistemas'), findsOneWidget);
      expect(find.text('Você já se candidatou'), findsOneWidget);
      expect(find.byTooltip('Adicionar aos interesses'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsNothing);
      expect(vagasService.idsConsultados, [8]);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.byType(DetalhesCandidaturaScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.byType(CandidaturasScreen), findsOneWidget);
    },
  );

  testWidgets('detalhes exibem status em análise e rejeitado', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appCandidaturas());
    await tester.pumpAndSettle();

    final emAnalise = find.text('Desenvolvedor .NET');
    await tester.ensureVisible(emAnalise);
    await tester.pumpAndSettle();
    await tester.tap(emAnalise);
    await tester.pumpAndSettle();
    expect(find.text('Em análise'), findsNWidgets(2));
    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('Entrevista'), findsNothing);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    final filtroRejeitado = find.text('Rejeitado (1)');
    await tester.ensureVisible(filtroRejeitado);
    await tester.pumpAndSettle();
    await tester.tap(filtroRejeitado);
    await tester.pumpAndSettle();

    final rejeitada = find.text('Técnico de Suporte');
    await tester.ensureVisible(rejeitada);
    await tester.pumpAndSettle();
    await tester.tap(rejeitada);
    await tester.pumpAndSettle();
    expect(find.text('Rejeitado'), findsOneWidget);
    expect(find.text('Sobre a vaga'), findsNothing);
    expect(find.text('Ver vaga'), findsOneWidget);
  });

  testWidgets('vaga da Home continua permitindo uma nova candidatura', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetalhesVagaScreen(
          vaga: _candidaturas().first.vaga.copyWith(jaCandidatado: false),
          authService: _FakeAuthService(),
          vagasService: _CandidaturaVagasService(jaCandidatado: false),
          favoritosService: _MockFavoritosService(),
          candidaturasService: _FakeCandidaturasService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final candidatar = find.text('Candidatar-se');
    expect(candidatar, findsOneWidget);
    await tester.tap(candidatar);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar candidatura'), findsNWidgets(2));
    expect(find.byKey(const Key('confirmar-candidatura')), findsOneWidget);
  });

  testWidgets('cadastro rejeita dados inválidos sem chamar a API', (
    WidgetTester tester,
  ) async {
    final authService = _FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CadastroScreen(authService: authService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Candidato Teste');
    await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.enterText(find.byType(TextField).at(3), 'different');
    await tester.tap(find.text('Criar conta'));
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(authService.registrationCalls, 0);
    expect(find.byType(CadastroScreen), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'teste@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'short');
    await tester.enterText(find.byType(TextField).at(3), 'short');
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    expect(
      find.text('A senha deve ter pelo menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(authService.registrationCalls, 0);

    await tester.enterText(find.byType(TextField).at(2), 'senha-valida-123');
    await tester.enterText(find.byType(TextField).at(3), 'outra-senha-456');
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(authService.registrationCalls, 0);
  });
}

String _jwtPayload(Map<String, Object> payload) {
  return base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
}

class _FakeAuthService extends AuthService {
  _FakeAuthService()
    : super(
        apiClient: ApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: _MemorySessionStorage(),
      );
  int registrationCalls = 0;

  @override
  Future<AuthResponse> login({
    required String email,
    required String senha,
  }) async {
    return const AuthResponse(
      token: 'header.payload.signature',
      candidato: CandidatoAuth(
        id: 1,
        nomeCompleto: 'Candidato Teste',
        email: 'teste@teste.com',
      ),
    );
  }

  @override
  Future<void> registrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    registrationCalls++;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> possuiSessaoValida() async => false;
}

class _MemorySessionStorage implements SessionStorage {
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

class _MockHomeVagasService extends VagasService {
  _MockHomeVagasService() : super(authService: _FakeAuthService());

  @override
  Future<List<VagaMock>> listarVagas({
    String? cidade,
    String? modalidade,
  }) async => mockVagas;
}

class _MockFavoritosService extends FavoritosService {
  _MockFavoritosService() : super(authService: _FakeAuthService());

  @override
  Future<List<VagaMock>> listarFavoritos() async => mockFavoritos.vagas;
}

MaterialApp _appCandidaturas({_CandidaturaVagasService? vagasService}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: CandidaturasScreen(
      authService: _FakeAuthService(),
      vagasService: vagasService ?? _CandidaturaVagasService(),
      favoritosService: _MockFavoritosService(),
      candidaturasService: _FakeCandidaturasService(),
    ),
  );
}

List<CandidaturaModel> _candidaturas() {
  return [
    for (final (index, titulo, empresa, status) in [
      (0, 'Desenvolvedor .NET', 'XP Tecnologia', 'Pendente'),
      (1, 'Analista de Sistemas', 'TechSolutions', 'Aceita'),
      (2, 'Estágio em TI', 'Next Tecnologia', 'Pendente'),
      (3, 'Técnico de Suporte', 'HelpTech', 'Recusada'),
    ])
      CandidaturaModel.fromJson({
        'id': index + 1,
        'status': status,
        'dataCandidatura': '2026-10-07T09:00:00',
        'atualizadoEm': '2026-10-07T09:00:00',
        'vaga': {
          'id': index + 7,
          'titulo': titulo,
          'nomeFantasiaEmpresa': empresa,
          'cidade': 'Sorocaba',
          'uf': 'SP',
          'modalidade': 'Hibrido',
        },
      }),
  ];
}

class _FakeCandidaturasService extends CandidaturasService {
  _FakeCandidaturasService() : super(authService: _FakeAuthService());

  @override
  Future<List<CandidaturaModel>> listarCandidaturas() async => _candidaturas();
}

class _CandidaturaVagasService extends VagasService {
  _CandidaturaVagasService({this.jaCandidatado = true})
    : super(authService: _FakeAuthService());

  final bool jaCandidatado;
  final List<int> idsConsultados = [];

  @override
  Future<VagaMock> obterVaga(int id) async {
    idsConsultados.add(id);
    return _candidaturas()
        .firstWhere((item) => item.vaga.id == id)
        .vaga
        .copyWith(jaCandidatado: jaCandidatado);
  }
}

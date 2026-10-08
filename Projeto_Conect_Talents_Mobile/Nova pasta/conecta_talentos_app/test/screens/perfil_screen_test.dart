import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/models/perfil_model.dart';
import 'package:conecta_talentos_app/screens/editar_perfil_screen.dart';
import 'package:conecta_talentos_app/screens/login_screen.dart';
import 'package:conecta_talentos_app/screens/meus_interesses_screen.dart';
import 'package:conecta_talentos_app/screens/perfil_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:conecta_talentos_app/widgets/app_header.dart';

void main() {
  testWidgets('Perfil mostra loading e depois os dados reais da conta', (
    tester,
  ) async {
    _configurarTela(tester);
    final resposta = Completer<PerfilModel>();
    final perfil = _FakePerfilService()..resposta = resposta.future;
    await tester.pumpWidget(_app(perfil));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<AppHeader>(find.byType(AppHeader)).userName,
      'Candidato',
    );
    resposta.complete(_dadosPerfil());
    await tester.pumpAndSettle();

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('joao@example.test'), findsOneWidget);
    expect(find.text('Sorocaba, SP'), findsOneWidget);
    expect(find.text('Candidato'), findsOneWidget);
    expect(
      tester.widget<AppHeader>(find.byType(AppHeader)).userName,
      'João da Silva',
    );
    expect(find.text('Em busca de novas oportunidades.'), findsNothing);
    expect(find.text('Treinamentos'), findsNothing);
    expect(find.text('Certificados'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(
      tester.widget<AppHeader>(find.byType(AppHeader)).hasUnreadNotifications,
      isFalse,
    );
  });

  testWidgets('Perfil aceita campos opcionais nulos sem inventar localidade', (
    tester,
  ) async {
    final perfil = _FakePerfilService()
      ..retorno = PerfilModel(
        id: 1008,
        nomeCompleto: 'João da Silva',
        email: 'joao@example.test',
        criadoEm: DateTime(2026, 10, 7),
      );
    await _abrir(tester, perfil);

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('joao@example.test'), findsOneWidget);
    expect(find.text('Sorocaba, SP'), findsNothing);
    expect(_valorEstatistica('Habilidades', '0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro do GET mantém menu e permite tentar novamente', (
    tester,
  ) async {
    final perfil = _FakePerfilService()
      ..falha = const ApiException('Servidor indisponível', statusCode: 500);
    await _abrir(tester, perfil);

    expect(find.text('Não foi possível carregar seu perfil.'), findsOneWidget);
    expect(find.text('Meus interesses'), findsOneWidget);
    await _mostrarSaida(tester);
    expect(find.text('Sair da conta'), findsOneWidget);
    perfil.falha = null;
    await _irParaTopo(tester);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(perfil.chamadas, 2);
    expect(perfil.forceRefreshs, [false, true]);
    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('Não foi possível carregar seu perfil.'), findsNothing);
  });

  testWidgets('401 exibe sessão expirada e mantém logout disponível', (
    tester,
  ) async {
    final perfil = _FakePerfilService()
      ..falha = const ApiException(
        'Sua sessão expirou. Faça login novamente.',
        statusCode: 401,
      );
    await _abrir(tester, perfil);

    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
    await _mostrarSaida(tester);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('E-mail ou senha inválidos.'), findsNothing);
  });

  testWidgets(
    'estatísticas usam candidaturas, interesses e habilidades reais',
    (tester) async {
      final perfil = _FakePerfilService();
      final candidaturas = _FakeCandidaturasService()..quantidade = 4;
      final favoritos = _FakeFavoritosService()..quantidade = 2;
      await _abrir(
        tester,
        perfil,
        candidaturasService: candidaturas,
        favoritosService: favoritos,
      );

      expect(_valorEstatistica('Candidaturas', '4'), findsOneWidget);
      expect(_valorEstatistica('Interesses', '2'), findsOneWidget);
      expect(_valorEstatistica('Habilidades', '3'), findsOneWidget);
      expect(candidaturas.chamadas, 1);
      expect(favoritos.chamadas, 1);
    },
  );

  testWidgets('falha parcial mostra traço apenas na estatística indisponível', (
    tester,
  ) async {
    final candidaturas = _FakeCandidaturasService()
      ..falha = const ApiException('Falha na contagem');
    final favoritos = _FakeFavoritosService()..quantidade = 2;
    await _abrir(
      tester,
      _FakePerfilService(),
      candidaturasService: candidaturas,
      favoritosService: favoritos,
    );

    expect(find.text('João da Silva'), findsOneWidget);
    expect(_valorEstatistica('Candidaturas', '—'), findsOneWidget);
    expect(_valorEstatistica('Interesses', '2'), findsOneWidget);
    expect(_valorEstatistica('Habilidades', '3'), findsOneWidget);
    expect(find.text('Não foi possível carregar seu perfil.'), findsNothing);
  });

  testWidgets('falha nos interesses não mostra zero falso', (tester) async {
    final favoritos = _FakeFavoritosService()
      ..falha = const ApiException('Falha na contagem');
    await _abrir(tester, _FakePerfilService(), favoritosService: favoritos);

    expect(_valorEstatistica('Interesses', '—'), findsOneWidget);
    expect(_valorEstatistica('Candidaturas', '0'), findsOneWidget);
    expect(find.text('João da Silva'), findsOneWidget);
  });

  testWidgets('pull-to-refresh força GET do perfil e atualiza as contagens', (
    tester,
  ) async {
    final perfil = _FakePerfilService();
    final candidaturas = _FakeCandidaturasService();
    final favoritos = _FakeFavoritosService();
    await _abrir(
      tester,
      perfil,
      candidaturasService: candidaturas,
      favoritosService: favoritos,
    );

    perfil.retorno = _dadosPerfil(nome: 'Ana Souza', habilidades: 'Dart');
    candidaturas.quantidade = 2;
    favoritos.quantidade = 1;
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(perfil.forceRefreshs, [false, true]);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(_valorEstatistica('Candidaturas', '2'), findsOneWidget);
    expect(_valorEstatistica('Interesses', '1'), findsOneWidget);
    expect(_valorEstatistica('Habilidades', '1'), findsOneWidget);
  });

  testWidgets('contagens carregam ao abrir a aba e atualizam ao reabri-la', (
    tester,
  ) async {
    final perfil = _FakePerfilService();
    final candidaturas = _FakeCandidaturasService();
    final favoritos = _FakeFavoritosService();
    Widget aplicativo(bool ativo) => _app(
      perfil,
      isActive: ativo,
      candidaturasService: candidaturas,
      favoritosService: favoritos,
    );
    await tester.pumpWidget(aplicativo(false));
    await tester.pumpAndSettle();
    expect(candidaturas.chamadas, 0);
    expect(favoritos.chamadas, 0);

    await tester.pumpWidget(aplicativo(true));
    await tester.pumpAndSettle();
    expect(candidaturas.chamadas, 1);
    expect(favoritos.chamadas, 1);
    await tester.pumpWidget(aplicativo(false));
    await tester.pumpAndSettle();
    favoritos.quantidade = 3;
    await tester.pumpWidget(aplicativo(true));
    await tester.pumpAndSettle();

    expect(candidaturas.chamadas, 2);
    expect(favoritos.chamadas, 2);
    expect(_valorEstatistica('Interesses', '3'), findsOneWidget);
  });

  testWidgets('Meu currículo usa o perfil real e o mesmo serviço ao salvar', (
    tester,
  ) async {
    _configurarTela(tester);
    final perfil = _FakePerfilService();
    await _abrir(tester, perfil);
    await tester.tap(find.text('Meu currículo'));
    await tester.pumpAndSettle();

    final editor = tester.widget<EditarPerfilScreen>(
      find.byType(EditarPerfilScreen),
    );
    expect(editor.perfil, same(perfil.perfil));
    expect(editor.perfilService, same(perfil));
    await tester.enterText(find.byKey(const Key('perfil-nome')), 'Ana Souza');
    await tester.enterText(find.byKey(const Key('perfil-habilidades')), 'Dart');
    await tester.ensureVisible(find.byKey(const Key('salvar-perfil')));
    await tester.tap(find.byKey(const Key('salvar-perfil')));
    await tester.pumpAndSettle();

    expect(find.byType(EditarPerfilScreen), findsNothing);
    await _irParaTopo(tester);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(_valorEstatistica('Habilidades', '1'), findsOneWidget);
    expect(find.text('Perfil atualizado!'), findsOneWidget);
    expect(perfil.atualizacoes, 1);
  });

  testWidgets('toques repetidos em Meu currículo abrem apenas um editor', (
    tester,
  ) async {
    _configurarTela(tester);
    await _abrir(tester, _FakePerfilService());
    final menu = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('Meu currículo'),
        matching: find.byType(InkWell),
      ),
    );
    menu.onTap!();
    menu.onTap!();
    await tester.pumpAndSettle();

    expect(
      find.byType(EditarPerfilScreen, skipOffstage: false),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.byType(PerfilScreen), findsOneWidget);
  });

  testWidgets(
    'Meus interesses conserva serviços e atualiza estatística ao voltar',
    (tester) async {
      _configurarTela(tester);
      final perfil = _FakePerfilService();
      final auth = _FakeAuthService();
      final favoritos = _FakeFavoritosService()..quantidade = 1;
      final candidaturas = _FakeCandidaturasService();
      final vagas = VagasService(authService: auth);
      int? aba;
      await tester.pumpWidget(
        _app(
          perfil,
          authService: auth,
          favoritosService: favoritos,
          candidaturasService: candidaturas,
          vagasService: vagas,
          onNavigationItemSelected: (index) => aba = index,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Meus interesses'));
      await tester.tap(find.text('Meus interesses'));
      await tester.pumpAndSettle();

      final interesses = tester.widget<MeusInteressesScreen>(
        find.byType(MeusInteressesScreen),
      );
      expect(interesses.authService, same(auth));
      expect(interesses.favoritosService, same(favoritos));
      expect(interesses.vagasService, same(vagas));
      expect(interesses.candidaturasService, same(candidaturas));
      interesses.onNavigationItemSelected!(1);
      expect(aba, 1);

      favoritos.quantidade = 0;
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await _irParaTopo(tester);
      expect(_valorEstatistica('Interesses', '0'), findsOneWidget);
      expect(candidaturas.chamadas, 2);
    },
  );

  testWidgets(
    'logout cancelado conserva cache e logout confirmado limpa sessão',
    (tester) async {
      _configurarTela(tester);
      final perfil = _FakePerfilService();
      final auth = _FakeAuthService();
      await _abrir(tester, perfil, authService: auth);
      final sair = find.text('Sair da conta');
      await _mostrarSaida(tester);
      await tester.tap(sair);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(auth.logouts, 0);
      expect(perfil.perfil, isNotNull);
      await _mostrarSaida(tester);
      await tester.tap(sair);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      expect(auth.logouts, 1);
      expect(perfil.limpezas, 1);
      expect(perfil.perfil, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );
}

Future<void> _abrir(
  WidgetTester tester,
  _FakePerfilService perfil, {
  AuthService? authService,
  FavoritosService? favoritosService,
  CandidaturasService? candidaturasService,
}) async {
  await tester.pumpWidget(
    _app(
      perfil,
      authService: authService,
      favoritosService: favoritosService,
      candidaturasService: candidaturasService,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _app(
  _FakePerfilService perfil, {
  AuthService? authService,
  FavoritosService? favoritosService,
  CandidaturasService? candidaturasService,
  VagasService? vagasService,
  bool isActive = true,
  ValueChanged<int>? onNavigationItemSelected,
}) => MaterialApp(
  theme: AppTheme.light,
  home: PerfilScreen(
    perfilService: perfil,
    authService: authService ?? _FakeAuthService(),
    favoritosService: favoritosService ?? _FakeFavoritosService(),
    candidaturasService: candidaturasService ?? _FakeCandidaturasService(),
    vagasService: vagasService,
    isActive: isActive,
    onNavigationItemSelected: onNavigationItemSelected,
  ),
);

Finder _valorEstatistica(String rotulo, String valor) => find.descendant(
  of: find.byKey(ValueKey('perfil-estatistica-$rotulo')),
  matching: find.text(valor),
);

Finder _listaRolavel() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> _mostrarSaida(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Sair da conta'),
    250,
    scrollable: _listaRolavel(),
  );
  await tester.pumpAndSettle();
}

Future<void> _irParaTopo(WidgetTester tester) async {
  tester.state<ScrollableState>(_listaRolavel()).position.jumpTo(0);
  await tester.pumpAndSettle();
}

void _configurarTela(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

PerfilModel _dadosPerfil({
  String nome = 'João da Silva',
  String habilidades = 'C#; Flutter; SQL',
}) => PerfilModel(
  id: 1008,
  nomeCompleto: nome,
  email: 'joao@example.test',
  telefone: '(15) 99999-9999',
  cidade: 'Sorocaba',
  uf: 'SP',
  habilidades: habilidades,
  criadoEm: DateTime(2026, 10, 7),
);

class _FakePerfilService extends PerfilService {
  _FakePerfilService() : super(authService: _FakeAuthService());

  PerfilModel? _perfil;
  bool _carregando = false;
  String? _erro;
  PerfilModel retorno = _dadosPerfil();
  Future<PerfilModel>? resposta;
  Exception? falha;
  int chamadas = 0;
  int atualizacoes = 0;
  int limpezas = 0;
  final List<bool> forceRefreshs = [];

  @override
  PerfilModel? get perfil => _perfil;
  @override
  bool get carregando => _carregando;
  @override
  String? get erro => _erro;

  @override
  Future<void> carregarPerfil({bool forceRefresh = false}) async {
    if (_perfil != null && !forceRefresh) return;
    chamadas++;
    forceRefreshs.add(forceRefresh);
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      if (falha != null) throw falha!;
      _perfil = await (resposta ?? Future.value(retorno));
    } on Exception catch (error) {
      _erro = error is ApiException ? error.message : 'Erro de teste';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  @override
  Future<PerfilModel> atualizarPerfil({
    required String nomeCompleto,
    String? telefone,
    String? cidade,
    String? uf,
    String? habilidades,
  }) async {
    atualizacoes++;
    _perfil = PerfilModel(
      id: 1008,
      nomeCompleto: nomeCompleto,
      email: 'joao@example.test',
      telefone: telefone,
      cidade: cidade,
      uf: uf,
      habilidades: habilidades,
      criadoEm: DateTime(2026, 10, 7),
    );
    notifyListeners();
    return _perfil!;
  }

  @override
  void limparPerfil() {
    limpezas++;
    _perfil = null;
    _erro = null;
    notifyListeners();
  }
}

class _FakeAuthService extends AuthService {
  int logouts = 0;

  @override
  Future<void> logout() async => logouts++;

  @override
  Future<bool> possuiSessaoValida() async => false;
}

class _FakeCandidaturasService extends CandidaturasService {
  _FakeCandidaturasService() : super(authService: _FakeAuthService());

  int quantidade = 0;
  int chamadas = 0;
  Exception? falha;

  @override
  Future<List<CandidaturaModel>> listarCandidaturas() async {
    chamadas++;
    if (falha != null) throw falha!;
    return [
      for (var index = 0; index < quantidade; index++)
        CandidaturaModel(
          id: index + 1,
          status: CandidaturaStatus.emAnalise,
          dataCandidatura: DateTime(2026, 10, 7),
          atualizadoEm: DateTime(2026, 10, 7),
          vaga: _vaga(),
        ),
    ];
  }
}

class _FakeFavoritosService extends FavoritosService {
  _FakeFavoritosService() : super(authService: _FakeAuthService());

  int quantidade = 0;
  int chamadas = 0;
  Exception? falha;

  @override
  Future<List<VagaMock>> listarFavoritos() async {
    chamadas++;
    if (falha != null) throw falha!;
    return List.generate(quantidade, (_) => _vaga());
  }
}

VagaMock _vaga() => const VagaMock(
  id: 7,
  titulo: 'Analista mobile',
  empresa: 'Empresa Teste',
  local: 'Sorocaba, SP',
  modalidade: 'Remoto',
  sigla: 'ET',
  iconeModalidade: Icons.home_outlined,
  indiceDestaque: 0,
);

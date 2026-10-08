import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/screens/candidaturas_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_candidatura_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/favoritos_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:conecta_talentos_app/widgets/status_badge.dart';

void main() {
  testWidgets('candidaturas mostram loading e dados retornados pelo serviço', (
    WidgetTester tester,
  ) async {
    final resposta = Completer<List<CandidaturaModel>>();
    final service = _FakeCandidaturasService()..resposta = resposta.future;
    await tester.pumpWidget(_aplicativo(service));

    expect(find.text('Minhas candidaturas'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete([_candidatura()]);
    await tester.pumpAndSettle();

    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.text('Sorocaba, SP'), findsOneWidget);
    expect(find.text('Híbrido'), findsOneWidget);
    expect(find.text('Todas (1)'), findsOneWidget);
    expect(_statusVisiveis(tester), ['Em análise']);
    expect(find.text('Entrevista'), findsNothing);
    expect(find.text('Proposta'), findsNothing);
  });

  testWidgets('lista vazia orienta o candidato e permite atualizar', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService();
    await _abrir(tester, service);

    expect(find.text('Você ainda não possui candidaturas.'), findsOneWidget);
    expect(
      find.text('Candidate-se a uma vaga para acompanhar o processo por aqui.'),
      findsOneWidget,
    );
    expect(find.text('Todas (0)'), findsOneWidget);

    service.candidaturas = [_candidatura()];
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(service.chamadas, 2);
    expect(find.text('Backend Developer'), findsOneWidget);
  });

  testWidgets('erro ao carregar candidaturas permite tentar novamente', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService()
      ..erro = const ApiException('Servidor indisponível', statusCode: 500);
    await _abrir(tester, service);

    expect(
      find.text('Não foi possível carregar suas candidaturas.'),
      findsOneWidget,
    );
    service
      ..erro = null
      ..candidaturas = [_candidatura()];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(service.chamadas, 2);
    expect(find.text('Backend Developer'), findsOneWidget);
  });

  testWidgets('sessão expirada mostra a mensagem do serviço', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService()
      ..erro = const ApiException(
        'Sua sessão expirou. Faça login novamente.',
        statusCode: 401,
      );
    await _abrir(tester, service);

    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
    expect(find.text('E-mail ou senha inválidos.'), findsNothing);
  });

  testWidgets('filtros calculam contagens e filtram sem consultar a API', (
    WidgetTester tester,
  ) async {
    _definirTamanho(tester);
    final service = _FakeCandidaturasService()
      ..candidaturas = [
        _candidatura(),
        _candidatura(id: 11, status: 'Aceita', titulo: 'Analista de Sistemas'),
        _candidatura(id: 12, status: 'Recusada', titulo: 'Técnico de Suporte'),
      ];
    await _abrir(tester, service);

    expect(find.text('Todas (3)'), findsOneWidget);
    expect(find.text('Em análise (1)'), findsOneWidget);
    expect(find.text('Selecionado (1)'), findsOneWidget);
    expect(find.text('Rejeitado (1)'), findsOneWidget);

    await tester.ensureVisible(find.text('Selecionado (1)'));
    await tester.tap(find.text('Selecionado (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Analista de Sistemas'), findsOneWidget);
    expect(find.text('Backend Developer'), findsNothing);
    expect(find.text('Técnico de Suporte'), findsNothing);
    expect(_statusVisiveis(tester), ['Selecionado']);

    await tester.ensureVisible(find.text('Rejeitado (1)'));
    await tester.tap(find.text('Rejeitado (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Técnico de Suporte'), findsOneWidget);
    expect(_statusVisiveis(tester), ['Rejeitado']);

    await tester.ensureVisible(find.text('Em análise (1)'));
    await tester.tap(find.text('Em análise (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(_statusVisiveis(tester), ['Em análise']);
    expect(service.chamadas, 1);
  });

  testWidgets('filtro sem resultados informa o estado vazio do filtro', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService()..candidaturas = [_candidatura()];
    await _abrir(tester, service);

    await tester.ensureVisible(find.text('Selecionado (0)'));
    await tester.tap(find.text('Selecionado (0)'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma candidatura encontrada para este filtro.'),
      findsOneWidget,
    );
    expect(find.text('Você ainda não possui candidaturas.'), findsNothing);
    expect(service.chamadas, 1);
  });

  testWidgets('pull-to-refresh reflete alteração do status pela empresa', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService()..candidaturas = [_candidatura()];
    await _abrir(tester, service);
    expect(_statusVisiveis(tester), ['Em análise']);

    service.candidaturas = [_candidatura(status: 'Aceita')];
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();

    expect(service.chamadas, 2);
    expect(_statusVisiveis(tester), ['Selecionado']);
    expect(find.text('Em análise (0)'), findsOneWidget);
    expect(find.text('Selecionado (1)'), findsOneWidget);
  });

  testWidgets('abrir a aba novamente recarrega as candidaturas', (
    WidgetTester tester,
  ) async {
    final service = _FakeCandidaturasService();
    await tester.pumpWidget(_aplicativo(service, isActive: false));
    await tester.pumpAndSettle();
    expect(service.chamadas, 1);

    service.candidaturas = [_candidatura()];
    await tester.pumpWidget(_aplicativo(service, isActive: true));
    await tester.pumpAndSettle();

    expect(service.chamadas, 2);
    expect(find.text('Backend Developer'), findsOneWidget);
  });

  testWidgets(
    'detalhes mostram data e Ver vaga busca o ID com serviços iguais',
    (WidgetTester tester) async {
      _definirTamanho(tester);
      final auth = AuthService();
      final candidaturas = _FakeCandidaturasService()
        ..candidaturas = [_candidatura(status: 'Aceita')];
      final vagas = _FakeVagasService();
      final favoritos = FavoritosService(authService: auth);
      await tester.pumpWidget(
        _aplicativo(
          candidaturas,
          authService: auth,
          vagasService: vagas,
          favoritosService: favoritos,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backend Developer'));
      await tester.pumpAndSettle();

      expect(find.byType(DetalhesCandidaturaScreen), findsOneWidget);
      expect(find.text('Enviada em 07/10/2026'), findsOneWidget);
      expect(find.text('Empresa Teste'), findsOneWidget);
      expect(find.text('Sorocaba, SP'), findsOneWidget);
      expect(find.text('Híbrido'), findsOneWidget);
      expect(_statusVisiveis(tester), ['Selecionado']);
      expect(find.text('Candidatura'), findsOneWidget);
      expect(find.text('Em análise'), findsOneWidget);
      expect(find.text('Entrevista'), findsNothing);
      expect(find.text('Proposta'), findsNothing);

      await tester.tap(find.text('Ver vaga'));
      await tester.pumpAndSettle();

      final telaVaga = tester.widget<DetalhesVagaScreen>(
        find.byType(DetalhesVagaScreen),
      );
      expect(vagas.idsConsultados, [7]);
      expect(telaVaga.authService, same(auth));
      expect(telaVaga.vagasService, same(vagas));
      expect(telaVaga.favoritosService, same(favoritos));
      expect(telaVaga.candidaturasService, same(candidaturas));
      expect(
        find.text('Descrição completa retornada pela API.'),
        findsOneWidget,
      );
      expect(find.text('Você já se candidatou'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsNothing);
      expect(find.byTooltip('Remover dos interesses'), findsOneWidget);

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.byType(DetalhesCandidaturaScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.byType(CandidaturasScreen), findsOneWidget);
    },
  );
}

Future<void> _abrir(
  WidgetTester tester,
  _FakeCandidaturasService service,
) async {
  await tester.pumpWidget(_aplicativo(service));
  await tester.pumpAndSettle();
}

Widget _aplicativo(
  _FakeCandidaturasService service, {
  bool isActive = true,
  AuthService? authService,
  VagasService? vagasService,
  FavoritosService? favoritosService,
}) => MaterialApp(
  theme: AppTheme.light,
  home: CandidaturasScreen(
    authService: authService ?? AuthService(),
    candidaturasService: service,
    vagasService: vagasService ?? _FakeVagasService(),
    favoritosService: favoritosService,
    isActive: isActive,
  ),
);

List<String> _statusVisiveis(WidgetTester tester) => tester
    .widgetList<StatusBadge>(find.byType(StatusBadge))
    .map((badge) => badge.text)
    .toList();

void _definirTamanho(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

CandidaturaModel _candidatura({
  int id = 10,
  String status = 'Pendente',
  String titulo = 'Backend Developer',
}) => CandidaturaModel.fromJson({
  'id': id,
  'status': status,
  'dataCandidatura': '2026-10-07T12:00:00',
  'atualizadoEm': '2026-10-07T12:00:00',
  'vaga': {
    'id': 7,
    'titulo': titulo,
    'nomeFantasiaEmpresa': 'Empresa Teste',
    'cidade': 'Sorocaba',
    'uf': 'SP',
    'modalidade': 'Hibrido',
  },
});

class _FakeCandidaturasService extends CandidaturasService {
  _FakeCandidaturasService() : super(authService: AuthService());

  List<CandidaturaModel> candidaturas = [];
  Future<List<CandidaturaModel>>? resposta;
  Exception? erro;
  int chamadas = 0;

  @override
  Future<List<CandidaturaModel>> listarCandidaturas() async {
    chamadas++;
    if (resposta != null) return resposta!;
    if (erro != null) throw erro!;
    return candidaturas;
  }
}

class _FakeVagasService extends VagasService {
  _FakeVagasService() : super(authService: AuthService());

  final List<int> idsConsultados = [];

  @override
  Future<VagaMock> obterVaga(int id) async {
    idsConsultados.add(id);
    return VagaMock.fromJson({
      'id': id,
      'titulo': 'Backend Developer',
      'nomeFantasiaEmpresa': 'Empresa Teste',
      'cidade': 'Sorocaba',
      'uf': 'SP',
      'modalidade': 'Hibrido',
      'descricao': 'Descrição completa retornada pela API.',
      'requisitos': 'Dart; Flutter',
      'jaCandidatado': true,
      'favoritada': true,
    });
  }
}

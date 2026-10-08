import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/models/candidatura_model.dart';
import 'package:conecta_talentos_app/screens/candidatura_confirmacao_screen.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/candidaturas_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  testWidgets('confirmação mostra a vaga sem dados fictícios ou mensagem', (
    tester,
  ) async {
    await _abrirConfirmacao(tester, _FakeCandidaturasService());

    expect(find.text('Analista mobile'), findsOneWidget);
    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(
      find.text(
        'Ao confirmar, sua conta de candidato será vinculada a esta vaga.',
      ),
      findsOneWidget,
    );
    expect(find.text('Seus dados'), findsNothing);
    expect(find.text('Editar perfil'), findsNothing);
    expect(find.text('Mensagem para a empresa'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('vaga sem ID mostra erro sem enviar uma candidatura', (
    tester,
  ) async {
    final service = _FakeCandidaturasService();
    await _abrirConfirmacao(tester, service, vaga: _vaga(id: null));

    await tester.tap(find.byKey(const Key('confirmar-candidatura')));
    await tester.pump();

    expect(service.vagaIds, isEmpty);
    expect(
      find.text(
        'Não foi possível identificar esta vaga. Abra uma vaga novamente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Candidatura enviada!'), findsNothing);
  });

  testWidgets(
    'envio bloqueia cliques repetidos e voltar enquanto aguarda a API',
    (tester) async {
      final resposta = Completer<CandidaturaModel>();
      final service = _FakeCandidaturasService()..resposta = resposta.future;
      await _abrirConfirmacao(tester, service);

      await tester.tap(find.byKey(const Key('confirmar-candidatura')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirmar-candidatura')));
      await tester.pump();

      expect(service.vagaIds, [7]);
      expect(find.text('Enviando candidatura...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(CandidaturaConfirmacaoScreen), findsOneWidget);

      resposta.complete(_candidatura());
      await tester.pumpAndSettle();
      expect(find.text('Candidatura enviada!'), findsOneWidget);
    },
  );

  testWidgets('sucesso retorna true e solicita a aba Candidaturas', (
    tester,
  ) async {
    final service = _FakeCandidaturasService();
    bool? resultado;
    int? aba;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CandidaturaConfirmacaoScreen(
                      vaga: _vaga(),
                      candidaturasService: service,
                      onNavigationItemSelected: (index) => aba = index,
                    ),
                  ),
                );
              },
              child: const Text('Abrir confirmação'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir confirmação'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-candidatura')));
    await tester.pumpAndSettle();

    expect(service.vagaIds, [7]);
    expect(find.text('Candidatura enviada!'), findsOneWidget);
    expect(
      find.text('Sua candidatura para Analista mobile foi confirmada.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ir para candidaturas'));
    await tester.pumpAndSettle();

    expect(resultado, isTrue);
    expect(aba, 1);
    expect(find.byType(CandidaturaConfirmacaoScreen), findsNothing);
  });

  testWidgets('detalhes marcam jaCandidatado depois do sucesso', (
    tester,
  ) async {
    final service = _FakeCandidaturasService();
    await _abrirDetalhes(tester, service);
    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-candidatura')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para candidaturas'));
    await tester.pumpAndSettle();

    expect(service.vagaIds, [7]);
    expect(find.byType(DetalhesVagaScreen), findsOneWidget);
    expect(find.text('Você já se candidatou'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sucesso troca a aba e remove confirmação e detalhes da pilha', (
    tester,
  ) async {
    final service = _FakeCandidaturasService();
    int? aba;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => DetalhesVagaScreen(
                    vaga: _vaga(),
                    vagasService: _FakeVagasService(),
                    candidaturasService: service,
                    onNavigationItemSelected: (index) => aba = index,
                  ),
                ),
              ),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-candidatura')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para candidaturas'));
    await tester.pumpAndSettle();

    expect(aba, 1);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(CandidaturaConfirmacaoScreen), findsNothing);
    expect(find.byType(DetalhesVagaScreen), findsNothing);
    expect(Navigator.of(tester.element(find.text('Home'))).canPop(), isFalse);
  });

  testWidgets('409 mostra a mensagem e impede uma segunda candidatura', (
    tester,
  ) async {
    final service = _FakeCandidaturasService()
      ..erro = const ApiException(
        'Você já se candidatou a esta vaga',
        statusCode: 409,
      );
    int? aba;
    await _abrirDetalhes(
      tester,
      service,
      onNavigationItemSelected: (index) => aba = index,
    );
    await tester.tap(find.text('Candidatar-se'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-candidatura')));
    await tester.pumpAndSettle();

    expect(find.text('Você já se candidatou a esta vaga'), findsOneWidget);
    expect(find.text('Candidatura enviada!'), findsNothing);
    await tester.tap(find.text('Voltar à vaga'));
    await tester.pumpAndSettle();

    expect(service.vagaIds, [7]);
    expect(aba, isNull);
    expect(find.text('Você já se candidatou'), findsOneWidget);
    expect(find.text('Candidatar-se'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'GET iniciado antes do POST não desfaz jaCandidatado confirmado',
    (tester) async {
      final respostaVaga = Completer<VagaMock>();
      final vagas = _FakeVagasService()..resposta = respostaVaga.future;
      final service = _FakeCandidaturasService();
      await _abrirDetalhes(tester, service, vagasService: vagas);
      await tester.tap(find.text('Candidatar-se'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar-candidatura')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ir para candidaturas'));
      await tester.pumpAndSettle();

      respostaVaga.complete(_vaga());
      await tester.pumpAndSettle();

      expect(find.text('Você já se candidatou'), findsOneWidget);
      expect(find.text('Candidatar-se'), findsNothing);
    },
  );

  for (final erro in [
    const ApiException(
      'Esta vaga não está mais aceitando candidaturas',
      statusCode: 400,
    ),
    const ApiException('Vaga não encontrada', statusCode: 404),
    const ApiException(
      'Sua sessão expirou. Faça login novamente.',
      statusCode: 401,
    ),
  ]) {
    testWidgets('${erro.statusCode} mostra erro sem confirmar a candidatura', (
      tester,
    ) async {
      final service = _FakeCandidaturasService()..erro = erro;
      await _abrirConfirmacao(tester, service);
      await tester.tap(find.byKey(const Key('confirmar-candidatura')));
      await tester.pumpAndSettle();

      expect(service.vagaIds, [7]);
      expect(find.text(erro.message), findsOneWidget);
      expect(find.text('Candidatura enviada!'), findsNothing);
      expect(find.byType(CandidaturaConfirmacaoScreen), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });
  }
}

Future<void> _abrirConfirmacao(
  WidgetTester tester,
  CandidaturasService service, {
  VagaMock? vaga,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CandidaturaConfirmacaoScreen(
        vaga: vaga ?? _vaga(),
        candidaturasService: service,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirDetalhes(
  WidgetTester tester,
  CandidaturasService service, {
  VagasService? vagasService,
  ValueChanged<int>? onNavigationItemSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: DetalhesVagaScreen(
        vaga: _vaga(),
        vagasService: vagasService ?? _FakeVagasService(),
        candidaturasService: service,
        onNavigationItemSelected: onNavigationItemSelected,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

VagaMock _vaga({int? id = 7}) => VagaMock(
  id: id,
  titulo: 'Analista mobile',
  empresa: 'Empresa Teste',
  local: 'Sorocaba, SP',
  modalidade: 'Remoto',
  sigla: 'ET',
  iconeModalidade: Icons.home_outlined,
  descricao: 'Vaga teste',
  requisitos: const ['Flutter'],
  indiceDestaque: 0,
);

CandidaturaModel _candidatura() => CandidaturaModel(
  id: 10,
  status: CandidaturaStatus.emAnalise,
  dataCandidatura: DateTime(2026, 10, 7),
  atualizadoEm: DateTime(2026, 10, 7),
  vaga: _vaga().copyWith(jaCandidatado: true),
);

class _FakeCandidaturasService extends CandidaturasService {
  _FakeCandidaturasService() : super(authService: AuthService());

  final List<int> vagaIds = [];
  Future<CandidaturaModel>? resposta;
  Exception? erro;

  @override
  Future<CandidaturaModel> criarCandidatura(int vagaId) async {
    vagaIds.add(vagaId);
    final erroAtual = erro;
    if (erroAtual != null) throw erroAtual;
    final respostaPendente = resposta;
    if (respostaPendente != null) return respostaPendente;
    return _candidatura();
  }
}

class _FakeVagasService extends VagasService {
  _FakeVagasService() : super(authService: AuthService());

  Future<VagaMock>? resposta;

  @override
  Future<VagaMock> obterVaga(int id) async {
    final respostaPendente = resposta;
    if (respostaPendente != null) return respostaPendente;
    return _vaga();
  }
}

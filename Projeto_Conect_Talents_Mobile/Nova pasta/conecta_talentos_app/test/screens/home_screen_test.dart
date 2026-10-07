import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conecta_talentos_app/mock/mock_vagas.dart';
import 'package:conecta_talentos_app/screens/detalhes_vaga_screen.dart';
import 'package:conecta_talentos_app/screens/home_screen.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/vagas_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  testWidgets('Home mostra loading e depois as vagas carregadas', (
    WidgetTester tester,
  ) async {
    final service = _FakeVagasService()..pending = Completer<List<VagaMock>>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(authService: AuthService(), vagasService: service),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.pending!.complete([_vaga()]);
    await tester.pumpAndSettle();

    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Nuvem Tech'), findsOneWidget);
  });

  testWidgets('Home mostra estado vazio para lista sem vagas', (
    WidgetTester tester,
  ) async {
    await _abrirHome(tester, _FakeVagasService());

    expect(find.text('Nenhuma vaga disponível no momento.'), findsOneWidget);
  });

  testWidgets('Home mostra erro e permite tentar novamente', (
    WidgetTester tester,
  ) async {
    final service = _FakeVagasService()..error = Exception('API offline');
    await _abrirHome(tester, service);

    expect(find.text('Não foi possível carregar as vagas.'), findsOneWidget);
    expect(service.calls, 1);

    service.error = null;
    service.vagas = [_vaga()];
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Backend Developer'), findsOneWidget);
  });

  testWidgets('busca local filtra vagas e Ver todas limpa a busca', (
    WidgetTester tester,
  ) async {
    final service = _FakeVagasService()..vagas = [_vaga(), _vagaFrontend()];
    await _abrirHome(tester, service);
    expect(find.text('Frontend Pleno'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('vacancy-search')), 'frontend');
    await tester.pumpAndSettle();

    expect(find.text('Backend Developer'), findsNothing);
    expect(find.text('Frontend Pleno'), findsOneWidget);
    expect(service.calls, 1);

    await tester.enterText(
      find.byKey(const Key('vacancy-search')),
      'nuvem tech',
    );
    await tester.pumpAndSettle();
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Frontend Pleno'), findsNothing);
    expect(service.calls, 1);

    await tester.enterText(find.byKey(const Key('vacancy-search')), 'sorocaba');
    await tester.pumpAndSettle();
    expect(find.text('Backend Developer'), findsNothing);
    expect(find.text('Frontend Pleno'), findsOneWidget);
    expect(service.calls, 1);

    await tester.enterText(
      find.byKey(const Key('vacancy-search')),
      'presencial',
    );
    await tester.pumpAndSettle();
    expect(find.text('Frontend Pleno'), findsOneWidget);
    expect(service.calls, 1);

    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();
    expect(find.text('Backend Developer'), findsOneWidget);
    expect(find.text('Frontend Pleno'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('vacancy-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(service.calls, 1);
  });

  testWidgets('pull-to-refresh consulta novamente as vagas', (
    WidgetTester tester,
  ) async {
    final service = _FakeVagasService()..vagas = [_vaga()];
    await _abrirHome(tester, service);
    expect(service.calls, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
  });

  testWidgets('detalhes atualizam dados reais e respeitam jaCandidatado', (
    WidgetTester tester,
  ) async {
    final vagaInicial = _vaga();
    final vagaAtualizada = VagaMock.fromJson({
      'id': 7,
      'titulo': 'Backend Developer atualizado',
      'descricao': 'Descrição atualizada.',
      'requisitos': 'Dart; Flutter',
      'cidade': 'Campinas',
      'uf': 'SP',
      'modalidade': 'Remoto',
      'nomeFantasiaEmpresa': 'Nuvem Tech',
      'jaCandidatado': true,
      'favoritada': true,
    });
    final service = _FakeVagasService()..detalhe = vagaAtualizada;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetalhesVagaScreen(
          vaga: vagaInicial,
          authService: AuthService(),
          vagasService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Backend Developer atualizado'), findsOneWidget);
    expect(find.text('Descrição atualizada.'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Você já se candidatou'), findsOneWidget);
    expect(find.byTooltip('Remover dos interesses'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos interesses'));
    await tester.pump();
    expect(
      find.text('Favoritos serão sincronizados na próxima etapa.'),
      findsOneWidget,
    );
    expect(find.text('Você já se candidatou'), findsOneWidget);
  });
}

Future<void> _abrirHome(WidgetTester tester, _FakeVagasService service) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: HomeScreen(authService: AuthService(), vagasService: service),
    ),
  );
  await tester.pumpAndSettle();
}

VagaMock _vaga() => VagaMock.fromJson({
  'id': 7,
  'titulo': 'Backend Developer',
  'descricao': 'Criação de APIs.',
  'requisitos': 'Dart; Flutter',
  'cidade': 'Campinas',
  'uf': 'SP',
  'modalidade': 'Remoto',
  'nomeFantasiaEmpresa': 'Nuvem Tech',
  'jaCandidatado': false,
  'favoritada': false,
});

VagaMock _vagaFrontend() => VagaMock.fromJson({
  'id': 8,
  'titulo': 'Frontend Pleno',
  'descricao': 'Desenvolvimento web.',
  'requisitos': 'HTML; CSS',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'modalidade': 'Presencial',
  'nomeFantasiaEmpresa': 'Interface Labs',
  'jaCandidatado': false,
  'favoritada': false,
});

class _FakeVagasService extends VagasService {
  _FakeVagasService() : super(authService: AuthService());

  List<VagaMock> vagas = [];
  VagaMock? detalhe;
  Exception? error;
  Completer<List<VagaMock>>? pending;
  int calls = 0;
  int detailCalls = 0;

  @override
  Future<List<VagaMock>> listarVagas({
    String? cidade,
    String? modalidade,
  }) async {
    calls++;
    if (pending != null) return pending!.future;
    if (error case final exception?) throw exception;
    return vagas;
  }

  @override
  Future<VagaMock> obterVaga(int id) async {
    detailCalls++;
    if (error case final exception?) throw exception;
    return detalhe ?? _vaga();
  }
}

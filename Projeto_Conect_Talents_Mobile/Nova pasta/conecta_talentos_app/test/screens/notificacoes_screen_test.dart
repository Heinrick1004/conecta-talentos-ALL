import 'dart:async';
import 'dart:convert';

import 'package:conecta_talentos_app/screens/notificacoes_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/notificacoes_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';
import 'package:conecta_talentos_app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('mostra loading e a lista real com título, mensagem e data', (
    tester,
  ) async {
    final resposta = Completer<http.Response>();
    final harness = _Harness()..getPendente = resposta;
    await tester.pumpWidget(harness.app());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Você não possui notificações.'), findsNothing);

    resposta.complete(harness.respostaLista());
    await tester.pumpAndSettle();
    expect(find.text('Sua candidatura foi aceita'), findsOneWidget);
    expect(
      find.text('A candidatura para a vaga Flutter foi aceita.'),
      findsOneWidget,
    );
    expect(find.text('07/10/2026 às 20:30'), findsOneWidget);
    expect(find.text('1 não lida'), findsOneWidget);
    expect(harness.gets, 1);
    harness.dispose();
  });

  testWidgets('lista vazia apresenta orientação e permite pull-to-refresh', (
    tester,
  ) async {
    final harness = _Harness()..lista = [];
    await _abrir(tester, harness);
    expect(find.text('Você não possui notificações.'), findsOneWidget);
    expect(
      find.text('As atualizações das suas candidaturas aparecerão aqui.'),
      findsOneWidget,
    );
    harness.lista = [_notificacao()];
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(harness.gets, 2);
    expect(find.text('Sua candidatura foi aceita'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('erro de GET permite tentar novamente e carrega a lista', (
    tester,
  ) async {
    final harness = _Harness()..getStatus = 500;
    await _abrir(tester, harness);
    expect(
      find.text('Não foi possível carregar suas notificações.'),
      findsOneWidget,
    );
    expect(find.text('Você não possui notificações.'), findsNothing);
    harness.getStatus = 200;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(harness.gets, 2);
    expect(find.text('Sua candidatura foi aceita'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('401 mostra sessão expirada na listagem', (tester) async {
    final harness = _Harness()..getStatus = 401;
    await _abrir(tester, harness);
    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
    expect(find.text('E-mail ou senha inválidos.'), findsNothing);
    harness.dispose();
  });

  testWidgets(
    'lidas e não lidas têm estilos distintos e lida não envia PATCH',
    (tester) async {
      final harness = _Harness()
        ..lista = [_notificacao(), _notificacao(id: 16, lida: true)];
      await _abrir(tester, harness);
      final naoLida = tester.widget<AppCard>(
        find.byKey(const ValueKey('notificacao-15')),
      );
      final lida = tester.widget<AppCard>(
        find.byKey(const ValueKey('notificacao-16')),
      );
      expect(naoLida.gradient, isNotNull);
      expect(lida.gradient, isNull);
      expect(
        find.byKey(const ValueKey('notificacao-nao-lida-15')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notificacao-nao-lida-16')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('marcar-notificacao-16')));
      await tester.pumpAndSettle();
      expect(harness.patches, 0);
      harness.dispose();
    },
  );

  testWidgets('toques duplicados aguardam um PATCH antes de mudar para lida', (
    tester,
  ) async {
    final harness = _Harness()..patchPendente = Completer<http.Response>();
    await _abrir(tester, harness);
    final card = find.byKey(const ValueKey('marcar-notificacao-15'));
    await tester.tap(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pump();
    expect(harness.patches, 1);
    expect(harness.service.notificacoes.single.lida, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    harness.patchPendente!.complete(http.Response('', 204));
    await tester.pumpAndSettle();
    expect(harness.service.notificacoes.single.lida, isTrue);
    expect(find.byKey(const ValueKey('notificacao-nao-lida-15')), findsNothing);
    expect(find.text('1 não lida'), findsNothing);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(harness.patches, 1);
    harness.dispose();
  });

  testWidgets('falha PATCH mantém não lida e apresenta feedback controlado', (
    tester,
  ) async {
    final harness = _Harness()..patchStatus = 404;
    await _abrir(tester, harness);
    await tester.tap(find.byKey(const ValueKey('marcar-notificacao-15')));
    await tester.pumpAndSettle();
    expect(harness.service.notificacoes.single.lida, isFalse);
    expect(harness.service.estaMarcandoComoLida(15), isFalse);
    expect(
      find.byKey(const ValueKey('notificacao-nao-lida-15')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Notificação não encontrada.'), findsOneWidget);
    harness.dispose();
  });

  testWidgets('PATCH 401 mostra sessão expirada sem alterar leitura', (
    tester,
  ) async {
    final harness = _Harness()..patchStatus = 401;
    await _abrir(tester, harness);
    await tester.tap(find.byKey(const ValueKey('marcar-notificacao-15')));
    await tester.pumpAndSettle();
    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
    expect(harness.service.naoLidas, 1);
    harness.dispose();
  });

  testWidgets(
    'refresh falhando mantém lista anterior disponível para nova tentativa',
    (tester) async {
      final harness = _Harness();
      await _abrir(tester, harness);
      harness.getStatus = 500;
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(
        find.text('Não foi possível carregar suas notificações.'),
        findsOneWidget,
      );
      expect(find.text('Sua candidatura foi aceita'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(harness.service.naoLidas, 1);
      harness.dispose();
    },
  );

  testWidgets('abrir tela sempre força GET mesmo com cache prévio', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.service.carregarNotificacoes();
    harness.lista = [_notificacao(id: 16, lida: true)];
    await _abrir(tester, harness);
    expect(harness.gets, 2);
    expect(harness.service.notificacoes.single.id, 16);
    harness.dispose();
  });
}

Future<void> _abrir(WidgetTester tester, _Harness harness) async {
  await tester.pumpWidget(harness.app());
  await tester.pumpAndSettle();
}

Map<String, dynamic> _notificacao({int id = 15, bool lida = false}) => {
  'id': id,
  'titulo': 'Sua candidatura foi aceita',
  'mensagem': 'A candidatura para a vaga Flutter foi aceita.',
  'lida': lida,
  'criadoEm': '2026-10-07T20:30:00',
  'candidaturaId': 110,
};

class _Auth extends AuthService {
  @override
  Future<String?> obterToken() async => 'jwt-teste';
}

class _Harness {
  _Harness() {
    final auth = _Auth();
    service = NotificacoesService(
      authService: auth,
      apiClient: ApiClient(client: MockClient(_responder)),
    );
    perfil = PerfilService(authService: auth);
  }

  late final NotificacoesService service;
  late final PerfilService perfil;
  List<Map<String, dynamic>> lista = [_notificacao()];
  int getStatus = 200;
  int patchStatus = 204;
  int gets = 0;
  int patches = 0;
  Completer<http.Response>? getPendente;
  Completer<http.Response>? patchPendente;

  http.Response respostaLista() => http.Response(
    jsonEncode(lista),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> _responder(http.Request request) async {
    if (request.method == 'GET') {
      gets++;
      if (getPendente != null) return getPendente!.future;
      return getStatus == 200
          ? respostaLista()
          : http.Response('{}', getStatus);
    }
    patches++;
    expect(request.method, 'PATCH');
    expect(request.body, isEmpty);
    expect(request.headers['Authorization'], 'Bearer jwt-teste');
    if (patchPendente != null) return patchPendente!.future;
    return http.Response(
      patchStatus == 204
          ? ''
          : jsonEncode({'erro': 'Notificação não encontrada.'}),
      patchStatus,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Widget app() => MaterialApp(
    theme: AppTheme.light,
    home: NotificacoesScreen(
      notificacoesService: service,
      perfilService: perfil,
    ),
  );

  void dispose() {
    service.dispose();
    perfil.dispose();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:conecta_talentos_app/models/perfil_model.dart';
import 'package:conecta_talentos_app/screens/editar_perfil_screen.dart';
import 'package:conecta_talentos_app/services/api_client.dart';
import 'package:conecta_talentos_app/services/auth_service.dart';
import 'package:conecta_talentos_app/services/perfil_service.dart';
import 'package:conecta_talentos_app/theme/app_theme.dart';

void main() {
  testWidgets(
    'formulário é preenchido com o perfil real e e-mail só de leitura',
    (tester) async {
      final api = _ApiPerfil();
      await _abrirEditor(tester, api);

      expect(_texto(tester, 'nome'), 'João da Silva');
      expect(_texto(tester, 'email'), 'joao@example.com');
      expect(_texto(tester, 'telefone'), '(15) 99999-9999');
      expect(_texto(tester, 'cidade'), 'Sorocaba');
      expect(_texto(tester, 'uf'), 'SP');
      expect(_texto(tester, 'habilidades'), 'C#, Flutter, SQL');
      expect(_campo(tester, 'email').readOnly, isTrue);
      expect(
        find.text('O e-mail da conta não pode ser alterado.'),
        findsOneWidget,
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.byTooltip('Alterar foto'), findsNothing);
      expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
      expect(api.bodies, isEmpty);
    },
  );

  testWidgets('campos opcionais nulos são apresentados vazios', (tester) async {
    final perfil = PerfilModel.fromJson({
      ..._perfilJson(),
      'telefone': null,
      'cidade': null,
      'uf': null,
      'habilidades': null,
    });
    await _abrirEditor(tester, _ApiPerfil(), perfil: perfil);

    for (final campo in ['telefone', 'cidade', 'uf', 'habilidades']) {
      expect(_texto(tester, campo), isEmpty);
    }
    expect(_texto(tester, 'nome'), 'João da Silva');
    expect(_texto(tester, 'email'), 'joao@example.com');
    expect(tester.takeException(), isNull);
  });

  for (final caso in [
    ('nome', '   ', 'O nome completo é obrigatório.'),
    (
      'nome',
      List.filled(151, 'N').join(),
      'O nome completo deve ter no máximo 150 caracteres.',
    ),
    (
      'telefone',
      List.filled(31, '9').join(),
      'O telefone deve ter no máximo 30 caracteres.',
    ),
    (
      'cidade',
      List.filled(101, 'C').join(),
      'A cidade deve ter no máximo 100 caracteres.',
    ),
    ('uf', 'S', 'Informe uma UF com duas letras.'),
    ('uf', 'S1', 'Informe uma UF com duas letras.'),
    ('uf', 'SPA', 'Informe uma UF com duas letras.'),
  ]) {
    testWidgets(
      'validação impede PUT: ${caso.$3} (${caso.$1}/${caso.$2.length})',
      (tester) async {
        final api = _ApiPerfil();
        await _abrirEditor(tester, api);
        await _preencher(tester, caso.$1, caso.$2);
        await _salvar(tester);
        await tester.pumpAndSettle();

        expect(find.text(caso.$3), findsOneWidget);
        expect(api.bodies, isEmpty);
        expect(find.byType(EditarPerfilScreen), findsOneWidget);
        expect(_texto(tester, caso.$1), caso.$2);
      },
    );
  }

  testWidgets(
    'salvar envia apenas os cinco campos normalizados e retorna perfil',
    (tester) async {
      final api = _ApiPerfil();
      PerfilModel? resultado;
      await _abrirEditor(
        tester,
        api,
        onResultado: (perfil) => resultado = perfil,
      );
      await _preencher(tester, 'nome', '  Maria da Silva  ');
      await _preencher(tester, 'telefone', '  (15) 98888-7777  ');
      await _preencher(tester, 'cidade', '  Campinas  ');
      await _preencher(tester, 'uf', ' sp ');
      await _preencher(tester, 'habilidades', ' C# ; Flutter,,\n SQL;\n');
      await _salvar(tester);
      await tester.pumpAndSettle();

      expect(api.bodies, [
        {
          'nomeCompleto': 'Maria da Silva',
          'telefone': '(15) 98888-7777',
          'cidade': 'Campinas',
          'uf': 'SP',
          'habilidades': 'C#; Flutter; SQL',
        },
      ]);
      final body = api.bodies.single;
      for (final campo in ['email', 'id', 'candidatoId', 'senha', 'criadoEm']) {
        expect(body.containsKey(campo), isFalse);
      }
      expect(resultado, same(api.service.perfil));
      expect(resultado!.nomeCompleto, 'Maria da Silva');
      expect(resultado!.email, 'joao@example.com');
      expect(resultado!.cidade, 'Campinas');
      expect(resultado!.uf, 'SP');
      expect(resultado!.listaHabilidades, ['C#', 'Flutter', 'SQL']);
      expect(find.byType(EditarPerfilScreen), findsNothing);
      expect(find.text('Abrir editor'), findsOneWidget);
      expect(find.text('Perfil atualizado!'), findsNothing);
    },
  );

  testWidgets('limites de nome, telefone e cidade são aceitos', (tester) async {
    final api = _ApiPerfil();
    await _abrirEditor(tester, api);
    await _preencher(tester, 'nome', List.filled(150, 'N').join());
    await _preencher(tester, 'telefone', List.filled(30, '9').join());
    await _preencher(tester, 'cidade', List.filled(100, 'C').join());
    await _salvar(tester);
    await tester.pumpAndSettle();

    expect(api.bodies, hasLength(1));
    expect((api.bodies.single['nomeCompleto'] as String).length, 150);
    expect((api.bodies.single['telefone'] as String).length, 30);
    expect((api.bodies.single['cidade'] as String).length, 100);
    expect(find.byType(EditarPerfilScreen), findsNothing);
  });

  testWidgets('limpar os campos opcionais persiste null e mantém o e-mail', (
    tester,
  ) async {
    final api = _ApiPerfil();
    PerfilModel? resultado;
    await _abrirEditor(
      tester,
      api,
      onResultado: (perfil) => resultado = perfil,
    );
    for (final campo in ['telefone', 'cidade', 'uf']) {
      await _preencher(tester, campo, '   ');
    }
    await _preencher(tester, 'habilidades', ' ;,\n ');
    await _salvar(tester);
    await tester.pumpAndSettle();

    expect(api.bodies.single, {
      'nomeCompleto': 'João da Silva',
      'telefone': null,
      'cidade': null,
      'uf': null,
      'habilidades': null,
    });
    expect(resultado!.telefone, isNull);
    expect(resultado!.cidade, isNull);
    expect(resultado!.uf, isNull);
    expect(resultado!.habilidades, isNull);
    expect(resultado!.email, 'joao@example.com');
    expect(resultado!.listaHabilidades, isEmpty);
  });

  testWidgets('salvamento pendente bloqueia cliques, edição e voltar', (
    tester,
  ) async {
    final resposta = Completer<http.Response>();
    final api = _ApiPerfil()..resposta = resposta;
    await _abrirEditor(tester, api);
    await _salvar(tester);
    await tester.pump();
    await tester.tap(find.byKey(const Key('salvar-perfil')));
    await tester.pump();

    expect(api.bodies, hasLength(1));
    expect(find.text('Salvando...'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == 'Voltar',
            ),
          )
          .onPressed,
      isNull,
    );
    for (final campo in [
      'nome',
      'email',
      'telefone',
      'cidade',
      'uf',
      'habilidades',
    ]) {
      expect(_campo(tester, campo).enabled, isFalse);
    }
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(EditarPerfilScreen), findsOneWidget);

    resposta.complete(api.sucesso());
    await tester.pumpAndSettle();
    expect(find.byType(EditarPerfilScreen), findsNothing);
    expect(api.bodies, hasLength(1));
  });

  testWidgets(
    'erro da API preserva as edições e permite tentar salvar novamente',
    (tester) async {
      final api = _ApiPerfil()
        ..status = 400
        ..mensagem = 'Não foi possível salvar os dados informados.';
      PerfilModel? resultado;
      await _abrirEditor(
        tester,
        api,
        onResultado: (perfil) => resultado = perfil,
      );
      await _preencher(tester, 'nome', 'Maria da Silva');
      await _preencher(tester, 'cidade', 'Campinas');
      await _salvar(tester);
      await tester.pumpAndSettle();

      expect(find.text(api.mensagem), findsOneWidget);
      expect(_texto(tester, 'nome'), 'Maria da Silva');
      expect(_texto(tester, 'cidade'), 'Campinas');
      expect(_campo(tester, 'nome').enabled, isTrue);
      expect(api.service.perfil, isNull);
      expect(resultado, isNull);
      expect(find.byType(EditarPerfilScreen), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );

      api.status = 200;
      await _salvar(tester);
      await tester.pumpAndSettle();

      expect(api.bodies, hasLength(2));
      expect(api.bodies[1], api.bodies[0]);
      expect(resultado!.nomeCompleto, 'Maria da Silva');
      expect(find.byType(EditarPerfilScreen), findsNothing);
    },
  );

  testWidgets('401 mostra sessão expirada e mantém os dados editados', (
    tester,
  ) async {
    final api = _ApiPerfil()..status = 401;
    await _abrirEditor(tester, api);
    await _preencher(tester, 'nome', 'Maria da Silva');
    await _salvar(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Sua sessão expirou. Faça login novamente.'),
      findsOneWidget,
    );
    expect(find.text('E-mail ou senha inválidos.'), findsNothing);
    expect(_texto(tester, 'nome'), 'Maria da Silva');
    expect(find.byType(EditarPerfilScreen), findsOneWidget);
    expect(api.service.perfil, isNull);
  });

  testWidgets('voltar sem salvar retorna null sem fazer PUT', (tester) async {
    final api = _ApiPerfil();
    PerfilModel? resultado;
    bool retornou = false;
    await _abrirEditor(
      tester,
      api,
      onResultado: (perfil) {
        resultado = perfil;
        retornou = true;
      },
    );
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(retornou, isTrue);
    expect(resultado, isNull);
    expect(api.bodies, isEmpty);
    expect(find.byType(EditarPerfilScreen), findsNothing);
  });
}

Future<void> _abrirEditor(
  WidgetTester tester,
  _ApiPerfil api, {
  PerfilModel? perfil,
  ValueChanged<PerfilModel?>? onResultado,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final resultado = await Navigator.of(context).push<PerfilModel>(
                MaterialPageRoute<PerfilModel>(
                  builder: (_) => EditarPerfilScreen(
                    perfil: perfil ?? PerfilModel.fromJson(_perfilJson()),
                    perfilService: api.service,
                  ),
                ),
              );
              onResultado?.call(resultado);
            },
            child: const Text('Abrir editor'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir editor'));
  await tester.pumpAndSettle();
}

TextField _campo(WidgetTester tester, String campo) =>
    tester.widget<TextField>(find.byKey(Key('perfil-$campo')));

String _texto(WidgetTester tester, String campo) =>
    _campo(tester, campo).controller!.text;

Future<void> _preencher(WidgetTester tester, String campo, String texto) async {
  final finder = find.byKey(Key('perfil-$campo'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, texto);
  await tester.pump();
}

Future<void> _salvar(WidgetTester tester) async {
  final finder = find.byKey(const Key('salvar-perfil'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Map<String, dynamic> _perfilJson() => {
  'id': 1008,
  'nomeCompleto': 'João da Silva',
  'email': 'joao@example.com',
  'telefone': '(15) 99999-9999',
  'cidade': 'Sorocaba',
  'uf': 'SP',
  'habilidades': 'C#; Flutter, SQL',
  'criadoEm': '2026-10-07T20:00:00',
};

class _FakeAuthService extends AuthService {
  @override
  Future<String?> obterToken() async => 'jwt-teste';
}

class _ApiPerfil {
  final List<Map<String, dynamic>> bodies = [];
  int status = 200;
  String mensagem = 'Não foi possível atualizar seu perfil.';
  Completer<http.Response>? resposta;
  late final PerfilService service = PerfilService(
    authService: _FakeAuthService(),
    apiClient: ApiClient(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/candidato/perfil');
        expect(request.headers['authorization'], 'Bearer jwt-teste');
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        final respostaPendente = resposta;
        if (respostaPendente != null) return respostaPendente.future;
        return status == 200
            ? sucesso()
            : http.Response(jsonEncode({'erro': mensagem}), status);
      }),
    ),
  );

  http.Response sucesso() =>
      http.Response(jsonEncode({..._perfilJson(), ...bodies.last}), 200);
}

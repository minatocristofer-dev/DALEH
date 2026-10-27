import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';
import 'package:daleh_app/features/perfil/perfil_providers.dart';
import 'package:daleh_app/features/perfil/perfil_screen.dart';
import 'package:daleh_app/features/perfil/widgets/player_card.dart';

/// Mesmo padrão de `sumula_test.dart`: uma storage falsa que registra se
/// `limpar()` (chamado dentro de `AuthController.sair()`) foi de fato
/// acionado — sem precisar de login real nem de rede.
class _AuthStorageDeTeste implements AuthStorage {
  bool limpou = false;
  @override
  Future<void> salvarToken(String token) async {}
  @override
  Future<String?> obterToken() async => 'token-de-teste';
  @override
  Future<void> salvarModoAcesso(ModoAcesso modo) async {}
  @override
  Future<ModoAcesso> obterModoAcesso() async => ModoAcesso.jogador;
  @override
  Future<bool> obterOnboardingVisto() async => true;
  @override
  Future<void> salvarOnboardingVisto() async {}
  @override
  Future<void> limpar() async => limpou = true;
}

class _ApiClientNuncaUsado implements ApiClient {
  @override
  Future<List<dynamic>> getLista(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> enviarArquivo(
    String path, {
    required String token,
    required List<int> bytes,
    required String nomeArquivo,
    required String contentType,
  }) =>
      throw UnimplementedError();
}

/// Fake de `ApiClient` que de fato guarda estado — pra cobrir a seção DADOS
/// (apelido/pé dominante/posição), que agora vive direto no Perfil (ver
/// `_SecaoDados` em `perfil_screen.dart`).
class _ApiClientComEstado implements ApiClient {
  Map<String, dynamic> perfil;
  Map<String, dynamic>? ultimoCorpoPatch;
  String? ultimoCaminhoPatch;
  _ApiClientComEstado(this.perfil);

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async => perfil;

  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    ultimoCaminhoPatch = path;
    ultimoCorpoPatch = corpo;
    if (path == '/auth/me') {
      if (corpo?.containsKey('nickname') ?? false) perfil = {...perfil, 'nickname': corpo!['nickname']};
      if (corpo?.containsKey('dominantFoot') ?? false) perfil = {...perfil, 'dominantFoot': corpo!['dominantFoot']};
    } else if (path == '/auth/me/posicao') {
      final modalidades = (perfil['modalidades'] as List).map((m) {
        final mapa = m as Map<String, dynamic>;
        if (mapa['modalidade'] != corpo?['modalidade']) return mapa;
        return {...mapa, 'posicaoPrincipal': corpo?['posicaoPrincipal'], 'posicaoSecundaria': corpo?['posicaoSecundaria']};
      }).toList();
      perfil = {...perfil, 'modalidades': modalidades};
    }
    return perfil;
  }

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> enviarArquivo(
    String path, {
    required String token,
    required List<int> bytes,
    required String nomeArquivo,
    required String contentType,
  }) =>
      throw UnimplementedError();
}

Map<String, dynamic> _perfilJson({String? nickname, String? dominantFoot, List<Map<String, dynamic>>? modalidades}) {
  return {
    'id': 'user-1',
    'fullName': 'Jogador Teste',
    'nickname': nickname,
    'email': 'jogador@teste.com',
    'avatarUrl': null,
    'city': null,
    'state': null,
    'dominantFoot': dominantFoot,
    'bio': null,
    'modalidades': modalidades ?? [],
    'estatisticas': {
      'jogosDisputados': 0,
      'gols': 0,
      'assistencias': 0,
      'cartoesAmarelos': 0,
      'cartoesVermelhos': 0,
      'mvp': 0,
      'convocacoes': 0,
    },
    'timesAtuais': [],
    'timesAnteriores': [],
  };
}

MeuPerfil _perfil() => MeuPerfil.fromJson(_perfilJson());

/// Monta a tela com um `ApiClient` falso que de fato guarda estado, pra
/// cobrir os fluxos de edição (apelido/pé/posição) com sessão real.
Future<_ApiClientComEstado> _montarComEstado(WidgetTester tester, Map<String, dynamic> perfilInicial) async {
  // A seção DADOS fica abaixo do Player Card, que já é alto sozinho (ver
  // mesmo cuidado no teste de compartilhar mais acima) — sem aumentar a
  // viewport, o `ListView` nem chega a desenhar esses widgets (lazy
  // layout), e os finders por texto acham "0 widgets" mesmo sem erro.
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final api = _ApiClientComEstado(perfilInicial);
  final container = ProviderContainer(
    overrides: [
      authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
      apiClientProvider.overrideWithValue(api),
      // `meuPerfilProvider` de verdade passa por `comSessao` (token do
      // `authControllerProvider`), que só fica pronto depois de
      // `AuthController._carregarSessaoSalva()` (assíncrono) resolver — uma
      // corrida com o primeiro build da tela. Como esses testes querem
      // exercitar a leitura/escrita de verdade via `_ApiClientComEstado`
      // (não um valor fixo), contorna só o lado da sessão aqui, chamando o
      // repository direto com um token fixo.
      meuPerfilProvider.overrideWith((ref) => ref.read(perfilRepositoryProvider).meuPerfil('token-de-teste')),
    ],
  );
  addTearDown(container.dispose);
  container.read(authControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: PerfilScreen())),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  return api;
}

/// Monta a tela com uma sessão falsa (token presente, sem rede/Supabase de
/// verdade) — mesmo preparo de `sumula_test.dart`, necessário só nos testes
/// que tocam no botão "Sair" (os outros nem chegam a construir o
/// `authControllerProvider`, porque o `onPressed` só roda quando clicado).
Future<_AuthStorageDeTeste> _montarComSessao(WidgetTester tester, {required AsyncValue<MeuPerfil> perfil}) async {
  final storage = _AuthStorageDeTeste();
  final container = ProviderContainer(
    overrides: [
      authStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(_ApiClientNuncaUsado()),
      meuPerfilProvider.overrideWith((ref) => perfil.when(
            data: (p) => Future.value(p),
            error: (e, _) => Future.error(e),
            loading: () => Completer<MeuPerfil>().future,
          )),
    ],
  );
  addTearDown(container.dispose);
  container.read(authControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: PerfilScreen())),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : null,
  );
  setUpAll(() async {
    await initSupabase();
  });

  testWidgets('botão "Sair" aparece mesmo quando o perfil não carrega (bug real encontrado em QA)', (tester) async {
    await _montarComSessao(tester, perfil: const AsyncValue.error('erro de servidor', StackTrace.empty));

    expect(find.byTooltip('Sair'), findsOneWidget);
  });

  testWidgets('tocar em "Sair" desloga de verdade, mesmo com o perfil em erro', (tester) async {
    final storage = await _montarComSessao(tester, perfil: const AsyncValue.error('erro de servidor', StackTrace.empty));

    await tester.tap(find.byTooltip('Sair'));
    await tester.pump();

    expect(storage.limpou, isTrue);
  });

  testWidgets('carrega o perfil real e mostra o Player Card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [meuPerfilProvider.overrideWith((ref) => Future.value(_perfil()))],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerCard), findsOneWidget);
    expect(find.text('COMPARTILHAR PLAYER CARD'), findsOneWidget);
  });

  testWidgets('tocar em compartilhar aciona o botão sem crashar (fluxo de captura é coberto à parte)', (tester) async {
    // O card cresceu com a evolução visual da Fase 7 (glow do avatar, selo,
    // tagline em inglês) — aumenta a viewport do teste pra caber a tela
    // inteira sem precisar rolar até o botão.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [meuPerfilProvider.overrideWith((ref) => Future.value(_perfil()))],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // `RenderRepaintBoundary.toImage()` não completa dentro do harness de
    // `flutter_test` (não há rasterizador real) — por isso só verificamos
    // aqui que o toque entra no estado de carregamento sem lançar exceção;
    // a resiliência de `compartilharPlayerCard` quando a captura/o
    // compartilhamento não estão disponíveis é testada isoladamente em
    // `player_card_share_test.dart`.
    //
    // O card cresceu com a evolução visual da Fase 7 (glow do avatar, selo,
    // tagline em inglês) — o botão pode ficar fora da viewport padrão do
    // teste (800x600) até rolar a ListView até ele.
    await tester.ensureVisible(find.text('COMPARTILHAR PLAYER CARD'));
    await tester.tap(find.text('COMPARTILHAR PLAYER CARD'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('seção DADOS (apelido/pé dominante/posição — antes escondidos em Configurações)', () {
    testWidgets('sem modalidade cadastrada, não mostra o campo Posição (não existe o que editar)', (tester) async {
      await _montarComEstado(tester, _perfilJson());

      expect(find.text('Apelido'), findsOneWidget);
      expect(find.text('Perna dominante'), findsOneWidget);
      expect(find.text('Posição'), findsNothing);
    });

    testWidgets('editar apelido chama PATCH /auth/me e atualiza o texto exibido', (tester) async {
      final api = await _montarComEstado(tester, _perfilJson());

      expect(find.text('Nenhum apelido definido'), findsOneWidget);

      await tester.tap(find.text('Apelido'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Jota');
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(api.ultimoCaminhoPatch, '/auth/me');
      expect(api.ultimoCorpoPatch, {'nickname': 'Jota'});
      expect(find.text('Jota'), findsOneWidget);
    });

    testWidgets('editar perna dominante chama PATCH /auth/me com dominantFoot', (tester) async {
      final api = await _montarComEstado(tester, _perfilJson());

      await tester.tap(find.text('Perna dominante'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esquerdo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(api.ultimoCaminhoPatch, '/auth/me');
      expect(api.ultimoCorpoPatch, {'dominantFoot': 'Esquerdo'});
      expect(find.text('Esquerdo'), findsOneWidget);
    });

    testWidgets('editar posição chama PATCH /auth/me/posicao com a modalidade certa e atualiza o texto', (tester) async {
      final api = await _montarComEstado(
        tester,
        _perfilJson(modalidades: [
          {'modalidade': 'FUTSAL', 'label': 'Futsal', 'posicaoPrincipal': 'Fixo', 'posicaoSecundaria': null},
        ]),
      );

      expect(find.text('Fixo'), findsOneWidget);

      await tester.tap(find.text('Posição'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('posicao-principal-Pivô')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR'));
      await tester.pumpAndSettle();

      expect(api.ultimoCaminhoPatch, '/auth/me/posicao');
      expect(api.ultimoCorpoPatch, {'modalidade': 'FUTSAL', 'posicaoPrincipal': 'Pivô', 'posicaoSecundaria': null});
      expect(find.text('Pivô'), findsOneWidget);
    });
  });
}

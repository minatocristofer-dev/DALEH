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
  }) =>
      throw UnimplementedError();
}

MeuPerfil _perfil() {
  return MeuPerfil.fromJson({
    'id': 'user-1',
    'fullName': 'Jogador Teste',
    'email': 'jogador@teste.com',
    'avatarUrl': null,
    'city': null,
    'state': null,
    'dominantFoot': null,
    'bio': null,
    'modalidades': [],
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
  });
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
}

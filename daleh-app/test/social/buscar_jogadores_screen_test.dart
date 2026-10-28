import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/social/buscar_jogadores_screen.dart';

class _AuthStorageDeTeste implements AuthStorage {
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
  Future<void> limpar() async {}
}

/// Fake de `ApiClient` que de fato guarda estado — pra cobrir busca e
/// seguir/deixar de seguir direto dos resultados.
class _ApiClientDeTeste implements ApiClient {
  List<Map<String, dynamic>> resultadosDaBusca;
  String? ultimoQ;
  final List<String> seguiuIds = [];
  final List<String> deixouDeSeguirIds = [];
  _ApiClientDeTeste({this.resultadosDaBusca = const []});

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) async {
    final uri = Uri.parse('https://x$path');
    ultimoQ = uri.queryParameters['q'];
    return resultadosDaBusca;
  }

  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    final id = path.split('/')[2]; // /users/<id>/follow
    seguiuIds.add(id);
    return {};
  }

  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    final id = path.split('/')[2];
    deixouDeSeguirIds.add(id);
    return {};
  }

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
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

Future<_ApiClientDeTeste> _montar(WidgetTester tester, {List<Map<String, dynamic>> resultados = const []}) async {
  final api = _ApiClientDeTeste(resultadosDaBusca: resultados);
  final container = ProviderContainer(
    overrides: [
      authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
      apiClientProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  container.read(authControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: BuscarJogadoresScreen())),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  return api;
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

  testWidgets('estado inicial: convite pra buscar, sem chamar a API', (tester) async {
    final api = await _montar(tester);

    expect(find.text('Busque por nome, apelido ou e-mail de um jogador pra seguir.'), findsOneWidget);
    expect(api.ultimoQ, isNull);
  });

  testWidgets('termo curto demais mostra aviso sem chamar a API', (tester) async {
    final api = await _montar(tester);

    await tester.enterText(find.byType(TextField), 'a');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('Digite pelo menos 2 letras.'), findsOneWidget);
    expect(api.ultimoQ, isNull);
  });

  testWidgets('busca com resultado mostra nome/apelido e botão SEGUIR', (tester) async {
    final api = await _montar(tester, resultados: [
      {'id': 'user-2', 'fullName': 'Gabriel Souza', 'nickname': 'Gabi', 'avatarUrl': null, 'jaSegue': false},
    ]);

    await tester.enterText(find.byType(TextField), 'gabi');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(api.ultimoQ, 'gabi');
    expect(find.text('Gabi'), findsOneWidget);
    expect(find.text('SEGUIR'), findsOneWidget);
  });

  testWidgets('sem resultado mostra aviso de ninguém encontrado', (tester) async {
    await _montar(tester, resultados: []);
    // já monta sem busca: simula digitar e não achar nada
    await tester.enterText(find.byType(TextField), 'ninguemcomessenome');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('Ninguém encontrado'), findsOneWidget);
  });

  testWidgets('tocar em SEGUIR chama POST /users/:id/follow e vira SEGUINDO', (tester) async {
    final api = await _montar(tester, resultados: [
      {'id': 'user-2', 'fullName': 'Gabriel Souza', 'nickname': null, 'avatarUrl': null, 'jaSegue': false},
    ]);

    await tester.enterText(find.byType(TextField), 'gabriel');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SEGUIR'));
    await tester.pumpAndSettle();

    expect(api.seguiuIds, ['user-2']);
    expect(find.text('SEGUINDO'), findsOneWidget);
    expect(find.text('SEGUIR'), findsNothing);
  });

  testWidgets('tocar em SEGUINDO chama DELETE /users/:id/follow e volta pra SEGUIR', (tester) async {
    final api = await _montar(tester, resultados: [
      {'id': 'user-2', 'fullName': 'Gabriel Souza', 'nickname': null, 'avatarUrl': null, 'jaSegue': true},
    ]);

    await tester.enterText(find.byType(TextField), 'gabriel');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SEGUINDO'));
    await tester.pumpAndSettle();

    expect(api.deixouDeSeguirIds, ['user-2']);
    expect(find.text('SEGUIR'), findsOneWidget);
  });
}

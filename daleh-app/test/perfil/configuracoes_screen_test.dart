import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/perfil/configuracoes_screen.dart';

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

class _ApiClientDeTeste implements ApiClient {
  String? ultimoCaminhoExcluido;

  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    ultimoCaminhoExcluido = path;
    return {};
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : true,
  );
  setUpAll(() async {
    await initSupabase();
  });

  Future<_ApiClientDeTeste> montar(WidgetTester tester) async {
    final api = _ApiClientDeTeste();
    final container = ProviderContainer(
      overrides: [
        authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    // `AuthController` carrega o token salvo de forma assíncrona no
    // construtor — sem "tocar" o provider e dar um pump antes de interagir,
    // `excluirConta()` ainda veria `state.token == null` (igual ao mesmo
    // cuidado em `perfil_screen_test.dart`).
    container.read(authControllerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: ConfiguracoesScreen())),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('botão de confirmação fica desabilitado até digitar EXCLUIR (confirmação forte)', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();

    expect(find.text('EXCLUIR MINHA CONTA'), findsOneWidget);
    final botaoAntes = tester.widget<FilledButton>(find.ancestor(
      of: find.text('EXCLUIR MINHA CONTA'),
      matching: find.byType(FilledButton),
    ));
    expect(botaoAntes.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'EXCLUIR');
    await tester.pump();

    final botaoDepois = tester.widget<FilledButton>(find.ancestor(
      of: find.text('EXCLUIR MINHA CONTA'),
      matching: find.byType(FilledButton),
    ));
    expect(botaoDepois.onPressed, isNotNull);
  });

  testWidgets('confirmar a exclusão chama DELETE /auth/me', (tester) async {
    final api = await montar(tester);

    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'EXCLUIR');
    await tester.pump();
    await tester.tap(find.text('EXCLUIR MINHA CONTA'));
    await tester.pumpAndSettle();

    expect(api.ultimoCaminhoExcluido, '/auth/me');
  });

  testWidgets('cancelar não chama a exclusão', (tester) async {
    final api = await montar(tester);

    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(api.ultimoCaminhoExcluido, isNull);
    expect(find.text('Excluir conta'), findsNothing);
  });
}

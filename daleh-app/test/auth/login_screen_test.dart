import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/auth/login_screen.dart';
import 'package:daleh_app/features/support/fale_conosco_screen.dart';

class _AuthStorageDeTeste implements AuthStorage {
  String? _token;
  ModoAcesso _modo = ModoAcesso.jogador;

  @override
  Future<void> salvarToken(String token) async => _token = token;
  @override
  Future<String?> obterToken() async => _token;
  @override
  Future<void> salvarModoAcesso(ModoAcesso modo) async => _modo = modo;
  @override
  Future<ModoAcesso> obterModoAcesso() async => _modo;
  @override
  Future<bool> obterOnboardingVisto() async => true;
  @override
  Future<void> salvarOnboardingVisto() async {}
  @override
  Future<void> limpar() async => _token = null;
}

/// Fake de `ApiClient` que controla o resultado do login (sucesso ou
/// `ApiException`), pra cobrir o fluxo real sem rede.
class _ApiClientDeTeste implements ApiClient {
  String? erroDeLogin;
  int chamadasDeLogin = 0;

  @override
  Future<String> login(String email, String senha) async {
    chamadasDeLogin++;
    if (erroDeLogin != null) throw ApiException(erroDeLogin!);
    return 'token-de-teste';
  }

  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
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
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : null,
  );

  setUpAll(() async {
    await initSupabase();
  });

  Future<_ApiClientDeTeste> montar(WidgetTester tester, {bool telaGrande = false}) async {
    if (telaGrande) {
      // A tela cresce em telas pequenas de teste (640x480 padrão) com todo
      // o formulário + botão Google — aumenta a viewport só nos testes que
      // precisam ver o botão Google/rodapé sem rolar.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final api = _ApiClientDeTeste();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
        apiClientProvider.overrideWithValue(api),
      ],
      child: MaterialApp(home: LoginScreen(onIrParaCadastro: () {})),
    ));
    await tester.pump();
    await tester.pumpAndSettle();
    return api;
  }

  // A escolha de modo (Jogador/Dirigente/Locador) saiu da tela de login —
  // agora é feita numa tela própria (`SeletorModoScreen`), logo depois do
  // login, nunca antes das credenciais. Ver AuthController.mostrarSeletorModo.
  testWidgets('a tela de login não tem mais o seletor de modo embutido', (tester) async {
    await montar(tester);

    expect(find.byType(SegmentedButton<ModoAcesso>), findsNothing);
    expect(find.text('JOGADOR'), findsNothing);
    expect(find.text('DONO DE QUADRA'), findsNothing);
  });

  testWidgets('wordmark, slogan e textos de boas-vindas aparecem', (tester) async {
    await montar(tester);

    expect(find.text('DALEH'), findsOneWidget);
    expect(find.text('CADA JOGO CONSTRÓI SUA HISTÓRIA.'), findsOneWidget);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.text('Acesse sua conta para continuar.'), findsOneWidget);
  });

  testWidgets('senha começa oculta e o botão de olho alterna a visibilidade', (tester) async {
    await montar(tester);

    final campoSenha = tester.widget<TextField>(
      find.ancestor(of: find.text('Senha'), matching: find.byType(TextField)).first,
    );
    expect(campoSenha.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    final campoSenhaDepois = tester.widget<TextField>(
      find.ancestor(of: find.text('Senha'), matching: find.byType(TextField)).first,
    );
    expect(campoSenhaDepois.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('"Manter conectado" vem marcado por padrão e pode ser desmarcado', (tester) async {
    await montar(tester);

    Checkbox checkbox() => tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox().value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(checkbox().value, isFalse);
  });

  testWidgets('login bem-sucedido chama a API uma vez e não deixa erro na tela (navegação real é feita por _Raiz)', (tester) async {
    final api = await montar(tester);

    await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'jogador@teste.com');
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'senha123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(api.chamadasDeLogin, 1);
    expect(find.textContaining('incorretos'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('credenciais inválidas mostram a mensagem de erro do backend, sem crashar', (tester) async {
    final api = await montar(tester);
    api.erroDeLogin = 'E-mail ou senha incorretos.';

    await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'jogador@teste.com');
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'errada');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Esqueci minha senha" abre o Fale Conosco de verdade (não existe recuperação automática ainda)', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.byType(FaleConoscoScreen), findsOneWidget);
  });

  testWidgets('"Criar conta" aciona o callback de navegação pro cadastro', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool chamou = false;
    final api = _ApiClientDeTeste();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
        apiClientProvider.overrideWithValue(api),
      ],
      child: MaterialApp(home: LoginScreen(onIrParaCadastro: () => chamou = true)),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Criar conta'));
    await tester.tap(find.text('Criar conta'));
    await tester.pump();

    expect(chamou, isTrue);
  });

  testWidgets('botão "Continuar com Google" existe e não crasha ao tocar', (tester) async {
    await montar(tester, telaGrande: true);

    await tester.ensureVisible(find.text('Continuar com Google'));
    await tester.tap(find.text('Continuar com Google'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

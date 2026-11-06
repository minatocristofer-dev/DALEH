import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/matches/criar_jogo_screen.dart';
import 'package:daleh_app/shared/widgets/primary_button.dart';

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

/// Fake de `ApiClient` que guarda o último corpo enviado a `POST /matches`
/// — só o necessário pra conferir que o "Local" digitado vira `locationName`.
class _ApiClientDeTeste implements ApiClient {
  Map<String, dynamic>? ultimoCorpoPost;

  Map<String, dynamic> _partidaBase() => {
        'id': 'match-1',
        'createdById': 'user-1',
        'modalidadeId': 'modalidade-1',
        'modalidade': {'id': 'modalidade-1', 'key': 'SOCIETY', 'label': 'Society'},
        'scheduledAt': '2026-12-01T20:00:00.000Z',
        'status': 'scheduled',
        'visibility': 'public',
      };

  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    ultimoCorpoPost = corpo;
    return _partidaBase();
  }

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async => _partidaBase();

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) => throw UnimplementedError();
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

  Future<_ApiClientDeTeste> montar(WidgetTester tester) async {
    final api = _ApiClientDeTeste();
    final container = ProviderContainer(
      overrides: [
        authStorageProvider.overrideWithValue(_AuthStorageDeTeste()),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.read(authControllerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: CriarJogoScreen())),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('campo "Local" existe e é opcional (hint de quadra sem perfil no DALEH)', (tester) async {
    await montar(tester);

    expect(find.widgetWithText(TextField, 'Local (opcional)'), findsOneWidget);
    expect(find.textContaining('ainda não têm perfil no DALEH'), findsOneWidget);
  });

  testWidgets('preencher Local e criar manda locationName já sem espaço nas pontas', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = await montar(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Local (opcional)'), '  Quadra do Basso  ');
    await tester.tap(find.widgetWithText(TextField, 'Capacidade máxima (opcional)'));
    await tester.pump();

    // Data/horário são obrigatórios antes de criar — escolhe hoje (padrão
    // do showDatePicker) e um horário fixo, sem precisar abrir os pickers
    // de verdade (o estado é privado, então aciona pelos botões reais).
    await tester.tap(find.text('Escolher data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher horário'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Criar jogo'));
    await tester.tap(find.widgetWithText(PrimaryButton, 'Criar jogo'));
    await tester.pumpAndSettle();

    expect(api.ultimoCorpoPost?['locationName'], 'Quadra do Basso');
  });
}

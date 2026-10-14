import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/auth/login_screen.dart';

class FakeAuthStorage implements AuthStorage {
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

  Widget montar() => ProviderScope(
        overrides: [authStorageProvider.overrideWithValue(FakeAuthStorage())],
        child: MaterialApp(home: Scaffold(body: LoginScreen(onIrParaCadastro: () {}))),
      );

  // A escolha de modo (Jogador/Dirigente/Locador) saiu da tela de login —
  // agora é feita numa tela própria (`SeletorModoScreen`), logo depois do
  // login, nunca antes das credenciais. Ver AuthController.mostrarSeletorModo.
  testWidgets('a tela de login não tem mais o seletor de modo embutido', (tester) async {
    await tester.pumpWidget(montar());
    await tester.pump();

    expect(find.byType(SegmentedButton<ModoAcesso>), findsNothing);
    expect(find.text('JOGADOR'), findsNothing);
    expect(find.text('DONO DE QUADRA'), findsNothing);
  });
}

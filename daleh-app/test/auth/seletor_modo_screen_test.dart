import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/auth/seletor_modo_screen.dart';

class _AuthStorageFalsa implements AuthStorage {
  ModoAcesso _modo = ModoAcesso.jogador;
  @override
  Future<void> salvarToken(String token) async {}
  @override
  Future<String?> obterToken() async => null;
  @override
  Future<void> salvarModoAcesso(ModoAcesso modo) async => _modo = modo;
  @override
  Future<ModoAcesso> obterModoAcesso() async => _modo;
  @override
  Future<bool> obterOnboardingVisto() async => true;
  @override
  Future<void> salvarOnboardingVisto() async {}
  @override
  Future<void> limpar() async {}
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

  testWidgets('mostra as 3 opções (Jogador/Dirigente/Locador) e tocar em uma chama definirModoAcesso', (tester) async {
    final container = ProviderContainer(
      overrides: [authStorageProvider.overrideWithValue(_AuthStorageFalsa())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: SeletorModoScreen())),
    );
    await tester.pump();

    expect(find.text('JOGADOR'), findsOneWidget);
    expect(find.text('DIRIGENTE'), findsOneWidget);
    expect(find.text('LOCADOR'), findsOneWidget);

    await tester.tap(find.text('DIRIGENTE'));
    await tester.pump();

    expect(container.read(authControllerProvider).modoAcesso, ModoAcesso.dirigente);
    expect(container.read(authControllerProvider).mostrarSeletorModo, isFalse);
  });
}

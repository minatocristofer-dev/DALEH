import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daleh_app/app.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';

/// flutter_secure_storage não tem implementação real disponível em `flutter
/// test` (no Linux ele fala com o secret-service do SO via dbus, que não
/// existe no ambiente de teste) — a chamada trava pra sempre em vez de
/// falhar rápido. Substituímos por uma implementação em memória só pros
/// testes, sem tocar no armazenamento real usado pelo app.
class FakeAuthStorage implements AuthStorage {
  String? _token;

  @override
  Future<void> salvarToken(String token) async => _token = token;

  @override
  Future<String?> obterToken() async => _token;

  @override
  Future<void> limpar() async => _token = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AuthController escuta supabase.auth.onAuthStateChange desde o construtor
  // (login social) — sem isso, qualquer teste que monte o app inteiro quebra
  // com "You must initialize the supabase instance before calling
  // Supabase.instance", mesmo sem nenhum teste tocar em login social.
  // O Supabase por sua vez guarda sessão via shared_preferences, que também
  // precisa de um handler falso — não existe plugin de verdade em `flutter test`.
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : null,
  );

  setUpAll(() async {
    await initSupabase();
  });

  testWidgets('mostra a tela de login por padrão', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authStorageProvider.overrideWithValue(FakeAuthStorage())],
      child: const DalehApp(),
    ));
    // A sessão salva é carregada de forma assíncrona — precisa de mais de um
    // pump pra sair do spinner de "verificando sessão".
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsWidgets);
  });
}

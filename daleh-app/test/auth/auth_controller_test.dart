import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';

/// Storage falsa em memória: guarda de verdade o que foi salvo, pra poder
/// simular uma "sessão restaurada" (token + modo já presentes antes do
/// `AuthController` existir) nos testes de persistência.
class _AuthStorageFalsa implements AuthStorage {
  String? _token;
  ModoAcesso? _modo;
  bool _onboardingVisto = false;

  @override
  Future<void> salvarToken(String token) async => _token = token;
  @override
  Future<String?> obterToken() async => _token;
  @override
  Future<void> salvarModoAcesso(ModoAcesso modo) async => _modo = modo;
  @override
  Future<ModoAcesso> obterModoAcesso() async => _modo ?? ModoAcesso.jogador;
  @override
  Future<bool> obterOnboardingVisto() async => _onboardingVisto;
  @override
  Future<void> salvarOnboardingVisto() async => _onboardingVisto = true;
  @override
  Future<void> limpar() async => _token = null;
}

class _ApiClientFalso implements ApiClient {
  String tokenDevolvido = 'token-novo';
  String? erroAoExcluirConta;
  String? ultimoCaminhoExcluido;
  @override
  Future<String> login(String email, String senha) async => tokenDevolvido;
  @override
  Future<String> registrar(Map<String, dynamic> dto) async => tokenDevolvido;
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
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    ultimoCaminhoExcluido = path;
    if (erroAoExcluirConta != null) throw ApiException(erroAoExcluirConta!);
    return {};
  }
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

  // `sair()` aciona `supabase.auth.signOut()`, que por sua vez limpa a sessão
  // guardada via `SharedPreferencesStore.remove` — precisa responder algo
  // diferente de null aqui (o plugin faz um `!` em cima do retorno), senão
  // o teste de logout quebra com "Null check operator used on a null value".
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : true,
  );

  setUpAll(() async {
    await initSupabase();
  });

  test('login bem-sucedido autentica e liga mostrarSeletorModo (toda sessão NOVA passa pelo seletor)', () async {
    final controller = AuthController(_ApiClientFalso(), _AuthStorageFalsa());
    await Future.delayed(Duration.zero); // deixa `_carregarSessaoSalva` do construtor terminar

    final erro = await controller.login('a@b.com', 'senha');

    expect(erro, isNull);
    expect(controller.state.logado, isTrue);
    expect(controller.state.mostrarSeletorModo, isTrue);
  });

  test('definirModoAcesso persiste o modo e fecha o seletor — escolher o modo nunca muda o token/sessão', () async {
    final storage = _AuthStorageFalsa();
    final controller = AuthController(_ApiClientFalso(), storage);
    await Future.delayed(Duration.zero);
    await controller.login('a@b.com', 'senha');
    final tokenAntes = controller.state.token;

    await controller.definirModoAcesso(ModoAcesso.dirigente);

    expect(await storage.obterModoAcesso(), ModoAcesso.dirigente);
    expect(controller.state.modoAcesso, ModoAcesso.dirigente);
    expect(controller.state.mostrarSeletorModo, isFalse);
    expect(controller.state.token, tokenAntes);
  });

  test('abrirSeletorDeModo ("Trocar modo") reabre o seletor sem deslogar e sem apagar o modo atual', () async {
    final controller = AuthController(_ApiClientFalso(), _AuthStorageFalsa());
    await Future.delayed(Duration.zero);
    await controller.login('a@b.com', 'senha');
    await controller.definirModoAcesso(ModoAcesso.locador);

    controller.abrirSeletorDeModo();

    expect(controller.state.logado, isTrue);
    expect(controller.state.modoAcesso, ModoAcesso.locador);
    expect(controller.state.mostrarSeletorModo, isTrue);
  });

  test('sessão restaurada (app reaberto já logado) NUNCA liga mostrarSeletorModo — cai direto no último modo salvo',
      () async {
    final storage = _AuthStorageFalsa();
    await storage.salvarToken('token-existente');
    await storage.salvarModoAcesso(ModoAcesso.dirigente);

    final controller = AuthController(_ApiClientFalso(), storage);
    await Future.delayed(Duration.zero);

    expect(controller.state.logado, isTrue);
    expect(controller.state.modoAcesso, ModoAcesso.dirigente);
    expect(controller.state.mostrarSeletorModo, isFalse);
    expect(controller.state.verificandoSessao, isFalse);
  });

  test('sair() desloga e devolve o estado padrão (modo volta pro default, seletor some)', () async {
    final controller = AuthController(_ApiClientFalso(), _AuthStorageFalsa());
    await Future.delayed(Duration.zero);
    await controller.login('a@b.com', 'senha');
    await controller.definirModoAcesso(ModoAcesso.locador);

    await controller.sair();

    expect(controller.state.logado, isFalse);
    expect(controller.state.mostrarSeletorModo, isFalse);
  });

  test('excluirConta() chama DELETE /auth/me e desloga localmente quando o backend confirma', () async {
    final storage = _AuthStorageFalsa();
    final api = _ApiClientFalso();
    final controller = AuthController(api, storage);
    await Future.delayed(Duration.zero);
    await controller.login('a@b.com', 'senha');

    final erro = await controller.excluirConta();

    expect(erro, isNull);
    expect(api.ultimoCaminhoExcluido, '/auth/me');
    expect(controller.state.logado, isFalse);
    expect(await storage.obterToken(), isNull);
  });

  test('excluirConta() mantém a sessão logada e devolve a mensagem quando o backend recusa', () async {
    final storage = _AuthStorageFalsa();
    final api = _ApiClientFalso()..erroAoExcluirConta = 'Não foi possível excluir sua conta agora.';
    final controller = AuthController(api, storage);
    await Future.delayed(Duration.zero);
    await controller.login('a@b.com', 'senha');

    final erro = await controller.excluirConta();

    expect(erro, 'Não foi possível excluir sua conta agora.');
    expect(controller.state.logado, isTrue);
  });
}

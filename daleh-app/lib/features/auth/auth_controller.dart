import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/supabase_config.dart';

final apiClientProvider = Provider((ref) => ApiClient());
final authStorageProvider = Provider((ref) => AuthStorage());

class AuthState {
  final String? token;
  final bool carregando;
  final bool verificandoSessao;
  final ModoAcesso modoAcesso;
  final bool onboardingVisto;
  // true só logo depois de um login/cadastro/login social bem-sucedido nesta
  // abertura do app — é o sinal pra `_Raiz` mostrar o Seletor de Modo. Uma
  // sessão restaurada (app reaberto já logado) nunca liga essa flag: cai
  // direto no modo salvo, sem passar pelo seletor de novo. Também é ligada
  // por "Trocar modo" dentro do app, sem precisar deslogar.
  final bool mostrarSeletorModo;

  const AuthState({
    this.token,
    this.carregando = false,
    this.verificandoSessao = true,
    this.modoAcesso = ModoAcesso.jogador,
    this.onboardingVisto = true,
    this.mostrarSeletorModo = false,
  });

  bool get logado => token != null;

  AuthState copyWith({
    String? token,
    bool? carregando,
    bool? verificandoSessao,
    ModoAcesso? modoAcesso,
    bool? onboardingVisto,
    bool? mostrarSeletorModo,
  }) =>
      AuthState(
        token: token ?? this.token,
        carregando: carregando ?? this.carregando,
        verificandoSessao: verificandoSessao ?? this.verificandoSessao,
        modoAcesso: modoAcesso ?? this.modoAcesso,
        onboardingVisto: onboardingVisto ?? this.onboardingVisto,
        mostrarSeletorModo: mostrarSeletorModo ?? this.mostrarSeletorModo,
      );
}

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _api;
  final AuthStorage _storage;

  AuthController(this._api, this._storage) : super(const AuthState()) {
    _carregarSessaoSalva();
    _escutarLoginSocial();
  }

  Future<void> _carregarSessaoSalva() async {
    final token = await _storage.obterToken();
    final modo = await _storage.obterModoAcesso();
    final onboardingVisto = await _storage.obterOnboardingVisto();
    // Sessão restaurada (app reaberto já logado): nunca mostra o seletor de
    // modo de novo, cai direto no último modo salvo.
    state = state.copyWith(token: token, modoAcesso: modo, onboardingVisto: onboardingVisto, verificandoSessao: false);
  }

  void _escutarLoginSocial() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null || state.logado) return;
      try {
        final token = await _api.loginSocial(session.accessToken);
        await _storage.salvarToken(token);
        final modo = await _storage.obterModoAcesso();
        state = state.copyWith(token: token, modoAcesso: modo, mostrarSeletorModo: true);
      } catch (_) {
        // Falha na troca do token social — usuário permanece na tela de login.
      }
    });
  }

  Future<String?> login(String email, String senha) async {
    state = state.copyWith(carregando: true);
    try {
      final token = await _api.login(email, senha);
      await _storage.salvarToken(token);
      final modo = await _storage.obterModoAcesso();
      // Login bem-sucedido sempre passa pelo Seletor de Modo — mesmo quando
      // já existe um modo salvo de uma sessão anterior, o usuário pode
      // querer confirmar/trocar. Só a sessão restaurada automaticamente
      // (app reaberto sem deslogar) pula direto pro modo salvo.
      state = state.copyWith(token: token, modoAcesso: modo, carregando: false, mostrarSeletorModo: true);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(carregando: false);
      return e.message;
    } finally {
      state = state.copyWith(carregando: false);
    }
  }

  Future<String?> registrar(Map<String, dynamic> dto) async {
    state = state.copyWith(carregando: true);
    try {
      final token = await _api.registrar(dto);
      await _storage.salvarToken(token);
      state = state.copyWith(token: token, modoAcesso: ModoAcesso.jogador, carregando: false, mostrarSeletorModo: true);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(carregando: false);
      return e.message;
    } finally {
      state = state.copyWith(carregando: false);
    }
  }

  Future<void> entrarComGoogle() async {
    // No app nativo (Android/iOS) precisa de um "endereço de retorno" próprio
    // do app — sem isso, o Supabase tenta voltar pra localhost (usado só em
    // desenvolvimento web) e o navegador do celular não sabe reabrir o app.
    // Esse mesmo endereço precisa estar autorizado no painel do Supabase em
    // Authentication > URL Configuration > Redirect URLs.
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.dalehapp.daleh://login-callback/',
    );
  }

  /// Persiste o modo escolhido no Seletor de Modo e fecha o seletor. O modo
  /// em si não concede nenhuma permissão nova — só troca qual conjunto de
  /// telas o app mostra; quem autoriza ações continua sendo sempre o backend.
  Future<void> definirModoAcesso(ModoAcesso modo) async {
    await _storage.salvarModoAcesso(modo);
    state = state.copyWith(modoAcesso: modo, mostrarSeletorModo: false);
  }

  /// Reabre o Seletor de Modo sem deslogar — usado pelo "Trocar modo" dentro
  /// do app (Perfil / Locador). A mesma conta pode alternar entre os três
  /// modos livremente, quantas vezes quiser.
  void abrirSeletorDeModo() {
    state = state.copyWith(mostrarSeletorModo: true);
  }

  Future<void> concluirOnboarding() async {
    await _storage.salvarOnboardingVisto();
    state = state.copyWith(onboardingVisto: true);
  }

  Future<void> sair() async {
    await _storage.limpar();
    await supabase.auth.signOut();
    state = AuthState(verificandoSessao: false, onboardingVisto: state.onboardingVisto);
  }

  /// Exclusão da própria conta (`DELETE /auth/me`) — o backend anonimiza os
  /// dados pessoais em vez de apagar fisicamente (preserva histórico
  /// esportivo compartilhado com outros jogadores/times). Depois de
  /// confirmado no servidor, desloga localmente igual a `sair()`. Devolve
  /// a mensagem de erro em caso de falha, ou null em caso de sucesso.
  Future<String?> excluirConta() async {
    final token = state.token;
    if (token == null) return null;
    try {
      await _api.deleteAutenticado('/auth/me', token: token);
    } on ApiException catch (e) {
      return e.message;
    }
    await _storage.limpar();
    await supabase.auth.signOut();
    state = AuthState(verificandoSessao: false, onboardingVisto: state.onboardingVisto);
    return null;
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(apiClientProvider), ref.read(authStorageProvider));
});

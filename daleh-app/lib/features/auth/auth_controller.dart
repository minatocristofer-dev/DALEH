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

  const AuthState({this.token, this.carregando = false, this.verificandoSessao = true});

  bool get logado => token != null;

  AuthState copyWith({String? token, bool? carregando, bool? verificandoSessao}) => AuthState(
        token: token ?? this.token,
        carregando: carregando ?? this.carregando,
        verificandoSessao: verificandoSessao ?? this.verificandoSessao,
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
    state = state.copyWith(token: token, verificandoSessao: false);
  }

  void _escutarLoginSocial() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null || state.logado) return;
      try {
        final token = await _api.loginSocial(session.accessToken);
        await _storage.salvarToken(token);
        state = state.copyWith(token: token);
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
      state = state.copyWith(token: token, carregando: false);
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
      state = state.copyWith(token: token, carregando: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(carregando: false);
      return e.message;
    } finally {
      state = state.copyWith(carregando: false);
    }
  }

  Future<void> entrarComGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> sair() async {
    await _storage.limpar();
    await supabase.auth.signOut();
    state = const AuthState(verificandoSessao: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(apiClientProvider), ref.read(authStorageProvider));
});

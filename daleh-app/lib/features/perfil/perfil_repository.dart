import '../../core/api_client.dart';
import 'models/meu_perfil.dart';

/// Só chama o endpoint que já existe (`GET /auth/me`, adicionado na Fase 6) —
/// nenhum endpoint foi inventado.
class PerfilRepository {
  final ApiClient _api;
  PerfilRepository(this._api);

  Future<MeuPerfil> meuPerfil(String token) async {
    final resp = await _api.getMapa('/auth/me', token: token);
    return MeuPerfil.fromJson(resp);
  }

  /// Perfil público de outro jogador (Fase 7) — mesmo formato de
  /// `meuPerfil`, só que sem e-mail (o backend nunca devolve isso aqui).
  Future<MeuPerfil> perfilPublico(String userId, String token) async {
    final resp = await _api.getMapa('/users/$userId', token: token);
    return MeuPerfil.fromJson(resp);
  }
}

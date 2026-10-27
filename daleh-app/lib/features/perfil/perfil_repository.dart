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

  /// Edição do apelido (ver PerfilScreen).
  Future<MeuPerfil> atualizarApelido(String? nickname, String token) async {
    final resp = await _api.patchAutenticado('/auth/me', token: token, corpo: {'nickname': nickname});
    return MeuPerfil.fromJson(resp);
  }

  /// Edição do pé dominante (ver PerfilScreen).
  Future<MeuPerfil> atualizarPeDominante(String peDominante, String token) async {
    final resp = await _api.patchAutenticado('/auth/me', token: token, corpo: {'dominantFoot': peDominante});
    return MeuPerfil.fromJson(resp);
  }

  /// Edição da posição numa modalidade em que o jogador já está cadastrado
  /// (não cria vínculo com modalidade nova).
  Future<MeuPerfil> atualizarPosicao(
    String modalidade,
    String posicaoPrincipal,
    String? posicaoSecundaria,
    String token,
  ) async {
    final resp = await _api.patchAutenticado(
      '/auth/me/posicao',
      token: token,
      corpo: {'modalidade': modalidade, 'posicaoPrincipal': posicaoPrincipal, 'posicaoSecundaria': posicaoSecundaria},
    );
    return MeuPerfil.fromJson(resp);
  }

  /// Perfil público de outro jogador (Fase 7) — mesmo formato de
  /// `meuPerfil`, só que sem e-mail (o backend nunca devolve isso aqui).
  Future<MeuPerfil> perfilPublico(String userId, String token) async {
    final resp = await _api.getMapa('/users/$userId', token: token);
    return MeuPerfil.fromJson(resp);
  }

  /// Envia a foto já composta (rosto encaixado na camisa do DALEH, achatada
  /// num único PNG pelo `EditarFotoScreen`) pro `POST /users/me/avatar`.
  Future<MeuPerfil> enviarAvatar(List<int> pngBytes, String token) async {
    final resp = await _api.enviarArquivo(
      '/users/me/avatar',
      token: token,
      bytes: pngBytes,
      nomeArquivo: 'avatar.png',
      contentType: 'image/png',
    );
    return MeuPerfil.fromJson(resp);
  }
}

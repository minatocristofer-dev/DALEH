import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'daleh_access_token';
const _modoAcessoKey = 'daleh_modo_acesso';
const _onboardingVistoKey = 'daleh_onboarding_visto';

/// Mesma conta, três conjuntos de telas diferentes — escolhido numa tela
/// própria logo depois do login/cadastro (nunca um papel fixo no cadastro).
/// Um dirigente ou locador continua sendo um jogador comum; só muda qual
/// conjunto de telas abre depois do login. O modo em si NUNCA concede
/// permissão nenhuma — quem autoriza é sempre o backend (ver
/// `TeamDetail.possoGerenciar`, `VenuesService.exigirDono`).
enum ModoAcesso { jogador, dirigente, locador }

class AuthStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> salvarToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> obterToken() => _storage.read(key: _tokenKey);

  Future<void> salvarModoAcesso(ModoAcesso modo) => _storage.write(key: _modoAcessoKey, value: modo.name);

  // Default pra jogador: contas novas e sessões antigas (de antes desse
  // campo existir) sempre caem no modo normal, nunca direto na gestão de
  // time/quadra.
  Future<ModoAcesso> obterModoAcesso() async {
    final valor = await _storage.read(key: _modoAcessoKey);
    return ModoAcesso.values.firstWhere((m) => m.name == valor, orElse: () => ModoAcesso.jogador);
  }

  Future<bool> obterOnboardingVisto() async => (await _storage.read(key: _onboardingVistoKey)) == 'sim';

  Future<void> salvarOnboardingVisto() => _storage.write(key: _onboardingVistoKey, value: 'sim');

  Future<void> limpar() => _storage.delete(key: _tokenKey);

  /// Decodifica só o payload do JWT (sem verificar assinatura) — usado
  /// apenas pra exibir o e-mail na tela, nunca pra autorizar nada sensível.
  static Map<String, dynamic>? payloadDoToken(String token) {
    try {
      final partes = token.split('.');
      var payload = partes[1].replaceAll('-', '+').replaceAll('_', '/');
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      return jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'daleh_access_token';

class AuthStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> salvarToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> obterToken() => _storage.read(key: _tokenKey);

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

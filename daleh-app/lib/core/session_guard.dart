import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';
import 'api_client.dart';

/// Envolve uma chamada autenticada: pega o token atual, e se a API responder
/// 401 (sessão expirada/token inválido), desloga automaticamente — a tela
/// volta pro Login sozinha porque `app.dart` reage ao estado do
/// `authControllerProvider`.
Future<T> comSessao<T>(Ref ref, Future<T> Function(String token) acao) async {
  final token = ref.read(authControllerProvider).token;
  if (token == null) {
    throw ApiException('Sua sessão expirou. Entra de novo.', kind: ApiErrorKind.unauthorized);
  }
  try {
    return await acao(token);
  } on ApiException catch (e) {
    if (e.kind == ApiErrorKind.unauthorized) {
      await ref.read(authControllerProvider.notifier).sair();
    }
    rethrow;
  }
}

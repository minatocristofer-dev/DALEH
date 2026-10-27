import '../../core/api_client.dart';

/// "Fale Conosco" — mensagem mínima de suporte/sugestão/bug, sem sistema de
/// tickets completo dentro do app (sem status, sem resposta in-app).
class SupportRepository {
  final ApiClient _api;
  SupportRepository(this._api);

  Future<void> enviarMensagem({
    required String categoria,
    required String assunto,
    required String mensagem,
    required String token,
  }) {
    return _api.postAutenticado(
      '/support/tickets',
      token: token,
      corpo: {
        'category': categoria,
        'subject': assunto,
        'message': mensagem,
        'platform': 'android',
      },
    );
  }
}

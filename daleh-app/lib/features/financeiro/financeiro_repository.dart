import '../../core/api_client.dart';
import 'models/financeiro.dart';

/// Só chama os endpoints de `src/modules/finance`. O app nunca processa
/// pagamento: a chave PIX é só exibida pra o jogador copiar no app do banco.
class FinanceiroRepository {
  final ApiClient _api;
  FinanceiroRepository(this._api);

  Future<CobrancasDoTime> obterDoTime(String teamId, String token) async {
    final resp = await _api.getMapa('/finance/teams/$teamId/charges', token: token);
    return CobrancasDoTime.fromJson(resp);
  }

  Future<void> definirPix(String teamId, String token, {required String pixKey, required String pixNome}) {
    return _api.patchAutenticado(
      '/finance/teams/$teamId/pix',
      token: token,
      corpo: {'pixKey': pixKey, 'pixNome': pixNome},
    );
  }

  Future<void> criarCobranca(String teamId, String token, {required String titulo, required double valor}) {
    return _api.postAutenticado(
      '/finance/teams/$teamId/charges',
      token: token,
      corpo: {'titulo': titulo, 'valor': valor},
    );
  }

  Future<void> marcarPagamento(String chargeId, String alvoUserId, String token, {required bool pago}) {
    return _api.patchAutenticado(
      '/finance/charges/$chargeId/items/$alvoUserId',
      token: token,
      corpo: {'pago': pago},
    );
  }
}

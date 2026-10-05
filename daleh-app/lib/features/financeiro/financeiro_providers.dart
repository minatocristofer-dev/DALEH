import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'financeiro_repository.dart';
import 'models/financeiro.dart';

final financeiroRepositoryProvider = Provider((ref) => FinanceiroRepository(ref.read(apiClientProvider)));

final cobrancasDoTimeProvider = FutureProvider.autoDispose.family<CobrancasDoTime, String>((ref, teamId) {
  final repo = ref.read(financeiroRepositoryProvider);
  return comSessao(ref, (token) => repo.obterDoTime(teamId, token));
});

/// Ações de escrita. Retornam a mensagem de erro da API (ou null se deu certo),
/// igual `TeamsActions.definirNumeroCamisa`, pra UI mostrar sem exceção solta.
class FinanceiroActions {
  final Ref ref;
  FinanceiroActions(this.ref);

  FinanceiroRepository get _repo => ref.read(financeiroRepositoryProvider);

  Future<String?> definirPix(String teamId, {required String pixKey, required String pixNome}) {
    return _executar(teamId, (token) => _repo.definirPix(teamId, token, pixKey: pixKey, pixNome: pixNome));
  }

  Future<String?> criarCobranca(String teamId, {required String titulo, required double valor}) {
    return _executar(teamId, (token) => _repo.criarCobranca(teamId, token, titulo: titulo, valor: valor));
  }

  Future<String?> marcarPagamento(String teamId, String chargeId, String alvoUserId, {required bool pago}) {
    return _executar(teamId, (token) => _repo.marcarPagamento(chargeId, alvoUserId, token, pago: pago));
  }

  Future<String?> _executar(String teamId, Future<void> Function(String token) acao) async {
    try {
      await comSessao(ref, acao);
      ref.invalidate(cobrancasDoTimeProvider(teamId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final financeiroActionsProvider = Provider((ref) => FinanceiroActions(ref));

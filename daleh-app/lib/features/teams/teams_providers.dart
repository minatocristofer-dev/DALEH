import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'models/call_up.dart';
import 'models/team.dart';
import 'models/team_member.dart';
import 'teams_repository.dart';

final teamsRepositoryProvider = Provider((ref) => TeamsRepository(ref.read(apiClientProvider)));

final meusTimesProvider = FutureProvider.autoDispose<List<Team>>((ref) {
  final repo = ref.read(teamsRepositoryProvider);
  return comSessao(ref, (token) => repo.listarMeusTimes(token));
});

final teamDetailProvider = FutureProvider.autoDispose.family<TeamDetail, String>((ref, teamId) {
  final repo = ref.read(teamsRepositoryProvider);
  return comSessao(ref, (token) => repo.obterTime(teamId, token));
});

final convocacoesDoTimeProvider = FutureProvider.autoDispose.family<List<CallUp>, String>((ref, teamId) {
  final repo = ref.read(teamsRepositoryProvider);
  return comSessao(ref, (token) => repo.convocacoesDoTime(teamId, token));
});

final minhasConvocacoesProvider = FutureProvider.autoDispose<List<CallUp>>((ref) {
  final repo = ref.read(teamsRepositoryProvider);
  return comSessao(ref, (token) => repo.minhasConvocacoes(token));
});

/// ID do usuário logado, decodificado do JWT — usado pra descobrir o papel
/// dele dentro de um time (o backend não devolve "meuPapel" no detalhe do
/// time, só na listagem `/teams/mine`).
final meuUserIdProvider = Provider.autoDispose<String?>((ref) {
  final token = ref.watch(authControllerProvider).token;
  if (token == null) return null;
  return AuthStorage.payloadDoToken(token)?['sub'] as String?;
});

/// Ações que alteram estado no backend. Não guardam estado próprio — depois
/// de cada ação, invalidam os providers de leitura afetados pra recarregar
/// da API real (nada de atualização otimista fake).
class TeamsActions {
  final Ref ref;
  TeamsActions(this.ref);

  TeamsRepository get _repo => ref.read(teamsRepositoryProvider);

  Future<Team> criarTime({required String name, String? city, String? state}) async {
    final time = await comSessao(ref, (token) => _repo.criarTime(token, name: name, city: city, state: state));
    ref.invalidate(meusTimesProvider);
    return time;
  }

  Future<void> adicionarMembro(String teamId, {String? userId, String? email}) async {
    await comSessao(ref, (token) => _repo.adicionarMembro(teamId, token, userId: userId, email: email));
    ref.invalidate(teamDetailProvider(teamId));
    ref.invalidate(meusTimesProvider);
  }

  Future<void> atualizarPapel(String teamId, String alvoUserId, String papel) async {
    await comSessao(ref, (token) => _repo.atualizarPapel(teamId, alvoUserId, token, papel: papel));
    ref.invalidate(teamDetailProvider(teamId));
  }

  /// Define (ou limpa, se `numero` for null) o número da camisa de um
  /// jogador do elenco — quem escolhe é o administrador/capitão, nunca o
  /// próprio jogador. Reenvia o papel atual dele porque o backend exige
  /// esse campo em toda chamada deste endpoint.
  Future<String?> definirNumeroCamisa(String teamId, String alvoUserId, String papelAtual, int? numero) async {
    try {
      await comSessao(
        ref,
        (token) => _repo.atualizarPapel(teamId, alvoUserId, token, papel: papelAtual, numeroCamisa: numero),
      );
      ref.invalidate(teamDetailProvider(teamId));
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> removerMembro(String teamId, String alvoUserId) async {
    await comSessao(ref, (token) => _repo.removerMembro(teamId, alvoUserId, token));
    ref.invalidate(teamDetailProvider(teamId));
    ref.invalidate(meusTimesProvider);
  }

  Future<String?> enviarEscudo(String teamId, List<int> bytes, String contentType) async {
    try {
      await comSessao(ref, (token) => _repo.enviarEscudo(teamId, token, bytes: bytes, contentType: contentType));
      ref.invalidate(teamDetailProvider(teamId));
      ref.invalidate(meusTimesProvider);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> convocar(
    String teamId, {
    required String venueNameSnapshot,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    await comSessao(
      ref,
      (token) => _repo.convocar(
        teamId,
        token,
        venueNameSnapshot: venueNameSnapshot,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      ),
    );
    ref.invalidate(convocacoesDoTimeProvider(teamId));
  }

  Future<void> responderConvocacao(String callUpId, String status) async {
    await comSessao(ref, (token) => _repo.responderConvocacao(callUpId, token, status: status));
    ref.invalidate(minhasConvocacoesProvider);
  }
}

final teamsActionsProvider = Provider((ref) => TeamsActions(ref));

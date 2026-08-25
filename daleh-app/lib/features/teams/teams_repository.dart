import '../../core/api_client.dart';
import 'models/call_up.dart';
import 'models/team.dart';
import 'models/team_member.dart';

/// Só chama os endpoints que já existem em `src/modules/teams` — nenhum
/// endpoint foi inventado aqui. Ver mapeamento completo no relatório da Fase 1.
class TeamsRepository {
  final ApiClient _api;
  TeamsRepository(this._api);

  Future<List<Team>> listarMeusTimes(String token) async {
    final lista = await _api.getLista('/teams/mine', token: token);
    return lista.map((t) => Team.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<Team> criarTime(
    String token, {
    required String name,
    String? city,
    String? state,
    String? crestUrl,
  }) async {
    final resp = await _api.postAutenticado(
      '/teams',
      token: token,
      corpo: {
        'name': name,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (crestUrl != null && crestUrl.isNotEmpty) 'crestUrl': crestUrl,
      },
    );
    return Team.fromJson(resp as Map<String, dynamic>);
  }

  Future<TeamDetail> obterTime(String teamId, String token) async {
    final resp = await _api.getMapa('/teams/$teamId', token: token);
    return TeamDetail.fromJson(resp);
  }

  /// A API só aceita adicionar quem já tem conta no DALEH, por `userId` ou
  /// `email` exato — não existe endpoint de busca/autocomplete de jogadores.
  Future<void> adicionarMembro(String teamId, String token, {String? userId, String? email}) {
    return _api.postAutenticado(
      '/teams/$teamId/members',
      token: token,
      corpo: {
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  Future<void> atualizarPapel(String teamId, String alvoUserId, String token, {required String papel}) {
    return _api.patchAutenticado('/teams/$teamId/members/$alvoUserId', token: token, corpo: {'papel': papel});
  }

  Future<void> removerMembro(String teamId, String alvoUserId, String token) {
    return _api.deleteAutenticado('/teams/$teamId/members/$alvoUserId', token: token);
  }

  Future<List<CallUp>> convocar(
    String teamId,
    String token, {
    required String venueNameSnapshot,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    final lista = await _api.postAutenticado(
      '/teams/$teamId/call-ups',
      token: token,
      corpo: {
        'venueNameSnapshot': venueNameSnapshot,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
      },
    );
    return (lista as List).map((c) => CallUp.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<CallUp>> convocacoesDoTime(String teamId, String token) async {
    final lista = await _api.getLista('/teams/$teamId/call-ups', token: token);
    return lista.map((c) => CallUp.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<CallUp>> minhasConvocacoes(String token) async {
    final lista = await _api.getLista('/call-ups/mine', token: token);
    return lista.map((c) => CallUp.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<void> responderConvocacao(String callUpId, String token, {required String status}) {
    return _api.patchAutenticado('/call-ups/$callUpId/respond', token: token, corpo: {'status': status});
  }
}

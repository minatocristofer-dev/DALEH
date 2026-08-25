import '../../core/api_client.dart';
import 'models/match.dart';
import 'models/match_event.dart';

/// Só chama endpoints que já existem em `src/modules/matches` — nenhum
/// endpoint foi inventado (ver auditoria da Fase 2.0).
class MatchesRepository {
  final ApiClient _api;
  MatchesRepository(this._api);

  Future<Match> criarPartida(
    String token, {
    required String modalidade,
    String? venueId,
    required String scheduledAt,
    int? maxPlayers,
    String visibility = 'public',
  }) async {
    final resp = await _api.postAutenticado(
      '/matches',
      token: token,
      corpo: {
        'modalidade': modalidade,
        if (venueId != null && venueId.isNotEmpty) 'venueId': venueId,
        'scheduledAt': scheduledAt,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
        'visibility': visibility,
      },
    );
    return Match.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<Match>> minhasPartidas(String token) async {
    final lista = await _api.getLista('/matches/mine', token: token);
    return lista.map((m) => Match.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Match> obterPartida(String matchId, String token) async {
    final resp = await _api.getMapa('/matches/$matchId', token: token);
    return Match.fromJson(resp);
  }

  Future<void> atualizarStatus(String matchId, String token, {required String status}) {
    return _api.patchAutenticado('/matches/$matchId/status', token: token, corpo: {'status': status});
  }

  Future<void> confirmarPresenca(String matchId, String token) {
    return _api.postAutenticado('/matches/$matchId/attendance', token: token);
  }

  Future<void> cancelarPresenca(String matchId, String token) {
    return _api.deleteAutenticado('/matches/$matchId/attendance', token: token);
  }

  Future<MatchEvent> registrarEvento(
    String matchId,
    String token, {
    required String userId,
    required String eventType,
    int? minute,
  }) async {
    final resp = await _api.postAutenticado(
      '/matches/$matchId/events',
      token: token,
      corpo: {
        'userId': userId,
        'eventType': eventType,
        if (minute != null) 'minute': minute,
      },
    );
    return MatchEvent.fromJson(resp as Map<String, dynamic>);
  }

  /// Súmula digital (Fase 8) — só pra partidas com os dois times vinculados.
  /// O placar nunca é enviado por aqui: é sempre recalculado pelo backend a
  /// partir dos gols já registrados.
  Future<void> registrarGol(
    String matchId,
    String token, {
    required String scorerId,
    String? assistId,
    int? minute,
  }) {
    return _api.postAutenticado(
      '/matches/$matchId/goals',
      token: token,
      corpo: {
        'scorerId': scorerId,
        if (assistId != null) 'assistId': assistId,
        if (minute != null) 'minute': minute,
      },
    );
  }

  Future<void> elegerMvp(String matchId, String token, {required String userId}) {
    return _api.postAutenticado('/matches/$matchId/mvp', token: token, corpo: {'userId': userId});
  }
}

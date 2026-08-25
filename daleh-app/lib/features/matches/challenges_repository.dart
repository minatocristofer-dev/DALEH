import '../../core/api_client.dart';
import 'models/challenge_request.dart';
import 'models/meus_desafios.dart';
import 'models/team_challenge.dart';

class ChallengesRepository {
  final ApiClient _api;
  ChallengesRepository(this._api);

  Future<TeamChallenge> criarDesafio(
    String token, {
    required String teamId,
    required String modalidade,
    required String city,
    String? venueId,
    required String scheduledDate,
    required String scheduledTime,
    required String desiredLevel,
  }) async {
    final resp = await _api.postAutenticado(
      '/team-challenges',
      token: token,
      corpo: {
        'teamId': teamId,
        'modalidade': modalidade,
        'city': city,
        if (venueId != null && venueId.isNotEmpty) 'venueId': venueId,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'desiredLevel': desiredLevel,
      },
    );
    return TeamChallenge.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<TeamChallenge>> listarDesafios(String token, {String? city, String? modalidade}) async {
    final query = <String, String>{};
    if (city != null && city.isNotEmpty) query['city'] = city;
    if (modalidade != null && modalidade.isNotEmpty) query['modalidade'] = modalidade;
    final sufixo = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final lista = await _api.getLista('/team-challenges$sufixo', token: token);
    return lista.map((d) => TeamChallenge.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<MeusDesafios> meusDesafios(String token) async {
    final resp = await _api.getMapa('/team-challenges/mine', token: token);
    return MeusDesafios.fromJson(resp);
  }

  Future<ChallengeRequest> solicitar(String challengeId, String token, {required String requestingTeamId}) async {
    final resp = await _api.postAutenticado(
      '/team-challenges/$challengeId/requests',
      token: token,
      corpo: {'requestingTeamId': requestingTeamId},
    );
    return ChallengeRequest.fromJson(resp as Map<String, dynamic>);
  }

  Future<TeamChallenge> aceitar(String challengeId, String requestId, String token) async {
    final resp = await _api.postAutenticado(
      '/team-challenges/$challengeId/requests/$requestId/accept',
      token: token,
    );
    return TeamChallenge.fromJson(resp as Map<String, dynamic>);
  }
}

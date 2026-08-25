/// Espelha o ChallengeRequest (enum RequestStatus: PENDENTE|ACEITA|RECUSADA).
/// Os campos `requestingTeam*` só vêm quando incluído a partir de
/// `comoOrganizador[].requests` (GET /team-challenges/mine); os campos
/// `challenge*` só vêm a partir de `minhasSolicitacoes[]` do mesmo endpoint —
/// nunca os dois ao mesmo tempo.
class ChallengeRequest {
  final String id;
  final String challengeId;
  final String requestingTeamId;
  final String status;
  final DateTime createdAt;
  final String? requestingTeamName;
  final String? requestingTeamCrestUrl;
  final String? challengeOrganizerTeamName;
  final String? challengeCity;
  final DateTime? challengeScheduledDate;
  final String? challengeScheduledTime;
  final String? challengeStatus;

  ChallengeRequest({
    required this.id,
    required this.challengeId,
    required this.requestingTeamId,
    required this.status,
    required this.createdAt,
    this.requestingTeamName,
    this.requestingTeamCrestUrl,
    this.challengeOrganizerTeamName,
    this.challengeCity,
    this.challengeScheduledDate,
    this.challengeScheduledTime,
    this.challengeStatus,
  });

  factory ChallengeRequest.fromJson(Map<String, dynamic> json) {
    final requestingTeam = json['requestingTeam'] as Map<String, dynamic>?;
    final challenge = json['challenge'] as Map<String, dynamic>?;
    final challengeTeam = challenge?['team'] as Map<String, dynamic>?;
    return ChallengeRequest(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      requestingTeamId: json['requestingTeamId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      requestingTeamName: requestingTeam?['name'] as String?,
      requestingTeamCrestUrl: requestingTeam?['crestUrl'] as String?,
      challengeOrganizerTeamName: challengeTeam?['name'] as String?,
      challengeCity: challenge?['city'] as String?,
      challengeScheduledDate:
          challenge?['scheduledDate'] != null ? DateTime.parse(challenge!['scheduledDate'] as String) : null,
      challengeScheduledTime: challenge?['scheduledTime'] as String?,
      challengeStatus: challenge?['status'] as String?,
    );
  }

  bool get pendente => status == 'PENDENTE';
}

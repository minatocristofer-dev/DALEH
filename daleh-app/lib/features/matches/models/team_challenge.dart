import 'challenge_request.dart';

const niveisDesejados = ['iniciante', 'intermediario', 'avancado'];

/// Espelha o TeamChallenge (enum ChallengeStatus: ABERTA|CONFIRMADA|CANCELADA
/// — CANCELADA existe no schema mas nenhum endpoint a atribui ainda).
/// `matchId` só é preenchido quando o desafio é aceito — a partir daí existe
/// um Match de verdade com os dois times vinculados.
class TeamChallenge {
  final String id;
  final String teamId;
  final String? teamName;
  final String? teamCrestUrl;
  final String city;
  final String? venueId;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String desiredLevel;
  final String status;
  final String? opponentTeamId;
  final String? matchId;
  final String? modalidadeLabel;
  final List<ChallengeRequest> requests;

  TeamChallenge({
    required this.id,
    required this.teamId,
    this.teamName,
    this.teamCrestUrl,
    required this.city,
    this.venueId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.desiredLevel,
    required this.status,
    this.opponentTeamId,
    this.matchId,
    this.modalidadeLabel,
    this.requests = const [],
  });

  factory TeamChallenge.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>?;
    final modalidade = json['modalidade'] as Map<String, dynamic>?;
    return TeamChallenge(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      teamName: team?['name'] as String?,
      teamCrestUrl: team?['crestUrl'] as String?,
      city: json['city'] as String,
      venueId: json['venueId'] as String?,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: json['scheduledTime'] as String,
      desiredLevel: json['desiredLevel'] as String,
      status: json['status'] as String,
      opponentTeamId: json['opponentTeamId'] as String?,
      matchId: json['matchId'] as String?,
      modalidadeLabel: modalidade?['label'] as String?,
      requests: (json['requests'] as List? ?? [])
          .map((r) => ChallengeRequest.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get aberta => status == 'ABERTA';
  bool get confirmada => status == 'CONFIRMADA';
}

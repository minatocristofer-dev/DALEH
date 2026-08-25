/// Espelha o CallUp (`prisma/schema.prisma`, enum CallUpStatus: PENDENTE |
/// CONFIRMADO | RECUSADO). `teamName`/`teamCrestUrl` só vêm em
/// `GET /call-ups/mine` (include de team); `userFullName` só vem em
/// `GET /teams/:id/call-ups` (include de user) — não inventar um endpoint
/// que traga os dois ao mesmo tempo, ele não existe.
class CallUp {
  final String id;
  final String teamId;
  final String? matchId;
  final String userId;
  final String venueNameSnapshot;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String status;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final String? teamName;
  final String? teamCrestUrl;
  final String? userFullName;

  CallUp({
    required this.id,
    required this.teamId,
    this.matchId,
    required this.userId,
    required this.venueNameSnapshot,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    this.respondedAt,
    required this.createdAt,
    this.teamName,
    this.teamCrestUrl,
    this.userFullName,
  });

  factory CallUp.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return CallUp(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      matchId: json['matchId'] as String?,
      userId: json['userId'] as String,
      venueNameSnapshot: json['venueNameSnapshot'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: json['scheduledTime'] as String,
      status: json['status'] as String,
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      teamName: team?['name'] as String?,
      teamCrestUrl: team?['crestUrl'] as String?,
      userFullName: user?['fullName'] as String?,
    );
  }

  bool get pendente => status == 'PENDENTE';
  bool get confirmado => status == 'CONFIRMADO';
  bool get recusado => status == 'RECUSADO';
}

class MatchAttendance {
  final String id;
  final String matchId;
  final String userId;
  final String status; // confirmed | waitlist | declined
  final DateTime createdAt;
  final String? userFullName;
  final String? userAvatarUrl;
  // Escalação (só vem preenchido quando a partida tem os dois times — ver
  // MatchesService.comEscalacao): de qual time o participante é membro
  // ATIVO hoje e sua posição principal cadastrada pra modalidade desta
  // partida. Lido em tempo real, não congelado como o MatchEvent.teamId —
  // aqui é só "quem tá no time agora", não precisa de estabilidade
  // histórica. Fica null quando não determinável — nunca inventado.
  final String? teamId;
  final String? posicaoPrincipal;

  MatchAttendance({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.userFullName,
    this.userAvatarUrl,
    this.teamId,
    this.posicaoPrincipal,
  });

  factory MatchAttendance.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return MatchAttendance(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userFullName: user?['fullName'] as String?,
      userAvatarUrl: user?['avatarUrl'] as String?,
      teamId: json['teamId'] as String?,
      posicaoPrincipal: json['posicaoPrincipal'] as String?,
    );
  }

  bool get confirmado => status == 'confirmed';
  bool get naEspera => status == 'waitlist';
}

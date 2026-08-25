const tiposDeEventoDeJogo = ['goal', 'assist', 'yellow', 'red', 'mvp'];

class MatchEvent {
  final String id;
  final String matchId;
  final String userId;
  final String eventType;
  final int? minute;
  final String? userFullName;
  final String? userAvatarUrl;
  // Time do jogador CONGELADO no momento do evento (Fase 9) — nulo em
  // partida avulsa (sem times) ou em evento antigo de antes dessa coluna
  // existir, que não pôde ser determinado com segurança. Não é usado hoje
  // na UI (a súmula já mostra o placar calculado pelo backend), só
  // espelhado aqui pra ficar disponível pra uma tela de histórico futura.
  final String? teamId;
  final DateTime createdAt;

  MatchEvent({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.eventType,
    this.minute,
    this.userFullName,
    this.userAvatarUrl,
    this.teamId,
    required this.createdAt,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return MatchEvent(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      minute: json['minute'] as int?,
      userFullName: user?['fullName'] as String?,
      userAvatarUrl: user?['avatarUrl'] as String?,
      teamId: json['teamId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

String rotuloDoEvento(String eventType) {
  switch (eventType) {
    case 'goal':
      return 'Gol';
    case 'assist':
      return 'Assistência';
    case 'yellow':
      return 'Cartão amarelo';
    case 'red':
      return 'Cartão vermelho';
    case 'mvp':
      return 'MVP';
    default:
      return eventType;
  }
}

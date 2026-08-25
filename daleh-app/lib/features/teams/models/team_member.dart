/// Papéis definidos no backend (`PapelTime`, prisma/schema.prisma).
/// "DONO" NÃO é um papel de fato — é derivado comparando `Team.ownerId`
/// com o `userId` do membro, então não aparece aqui como valor possível.
const papeisDeGestao = ['CAPITAO', 'VICE_CAPITAO'];
const todosOsPapeisAtualizaveis = ['JOGADOR', 'CAPITAO', 'VICE_CAPITAO', 'TESOUREIRO'];

/// Estatísticas reais do jogador DENTRO deste time (`GET /teams/:id`),
/// calculadas pelo backend a partir do `MatchEvent.teamId` congelado
/// (Fase 9) — nunca inventadas nem derivadas do elenco atual, então não
/// regridem se alguém mudar de time depois de ter jogado.
class EstatisticasNoTime {
  final int jogos;
  final int gols;
  final int mvp;

  EstatisticasNoTime({required this.jogos, required this.gols, required this.mvp});

  factory EstatisticasNoTime.fromJson(Map<String, dynamic>? json) {
    int lerInt(String chave) => (json?[chave] as num?)?.toInt() ?? 0;
    return EstatisticasNoTime(jogos: lerInt('jogos'), gols: lerInt('gols'), mvp: lerInt('mvp'));
  }
}

class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final String papel;
  final String status;
  final String fullName;
  final String? avatarUrl;
  final EstatisticasNoTime estatisticas;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.papel,
    required this.status,
    required this.fullName,
    this.avatarUrl,
    required this.estatisticas,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return TeamMember(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      userId: json['userId'] as String,
      papel: json['papel'] as String,
      status: json['status'] as String,
      fullName: user?['fullName'] as String? ?? '',
      avatarUrl: user?['avatarUrl'] as String?,
      estatisticas: EstatisticasNoTime.fromJson(json['estatisticas'] as Map<String, dynamic>?),
    );
  }
}

/// Resultado de `GET /teams/:id`: dados do time + elenco ativo.
class TeamDetail {
  final String id;
  final String name;
  final String? crestUrl;
  final String? city;
  final String? state;
  final String ownerId;
  final List<TeamMember> members;

  TeamDetail({
    required this.id,
    required this.name,
    this.crestUrl,
    this.city,
    this.state,
    required this.ownerId,
    required this.members,
  });

  factory TeamDetail.fromJson(Map<String, dynamic> json) => TeamDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        crestUrl: json['crestUrl'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        ownerId: json['ownerId'] as String,
        members: (json['members'] as List? ?? [])
            .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  /// Papel do usuário logado dentro deste time, ou null se ele não estiver no elenco.
  TeamMember? membroPor(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  bool souDono(String userId) => ownerId == userId;

  bool possoGerenciar(String userId) {
    if (souDono(userId)) return true;
    final meu = membroPor(userId);
    return meu != null && papeisDeGestao.contains(meu.papel);
  }
}

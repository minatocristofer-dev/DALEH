/// Espelha o Team do Prisma (`prisma/schema.prisma`). `meuPapel` e
/// `totalMembros` só vêm preenchidos quando o time chega via
/// `GET /teams/mine` — em `GET /teams/:id` ficam nulos (esses dados aparecem
/// noutro formato lá: `owner` + lista de `members`).
class Team {
  final String id;
  final String name;
  final String? crestUrl;
  final String? city;
  final String? state;
  final String ownerId;
  final String? meuPapel;
  final int? totalMembros;

  Team({
    required this.id,
    required this.name,
    this.crestUrl,
    this.city,
    this.state,
    required this.ownerId,
    this.meuPapel,
    this.totalMembros,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        name: json['name'] as String,
        crestUrl: json['crestUrl'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        ownerId: json['ownerId'] as String,
        meuPapel: json['meuPapel'] as String?,
        totalMembros: json['totalMembros'] as int?,
      );

  bool souDono(String userId) => ownerId == userId;
}

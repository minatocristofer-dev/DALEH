/// Painel do Dirigente (QA Round 2, Priority 3) — espelha `GET
/// /teams/:id/dashboard`. Tudo aqui é dado real agregado pelo backend,
/// nada calculado/inventado no Flutter.
class JogoResumo {
  final String id;
  final DateTime scheduledAt;
  final String status;
  final String? venueName;
  final TimeResumoJogo? homeTeam;
  final TimeResumoJogo? awayTeam;
  final PlacarResumo? placar;

  JogoResumo({
    required this.id,
    required this.scheduledAt,
    required this.status,
    this.venueName,
    this.homeTeam,
    this.awayTeam,
    this.placar,
  });

  factory JogoResumo.fromJson(Map<String, dynamic> json) => JogoResumo(
        id: json['id'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        status: json['status'] as String,
        venueName: json['venueName'] as String?,
        homeTeam: json['homeTeam'] != null ? TimeResumoJogo.fromJson(json['homeTeam'] as Map<String, dynamic>) : null,
        awayTeam: json['awayTeam'] != null ? TimeResumoJogo.fromJson(json['awayTeam'] as Map<String, dynamic>) : null,
        placar: json['placar'] != null ? PlacarResumo.fromJson(json['placar'] as Map<String, dynamic>) : null,
      );
}

class TimeResumoJogo {
  final String id;
  final String name;
  final String? crestUrl;
  TimeResumoJogo({required this.id, required this.name, this.crestUrl});

  factory TimeResumoJogo.fromJson(Map<String, dynamic> json) =>
      TimeResumoJogo(id: json['id'] as String, name: json['name'] as String, crestUrl: json['crestUrl'] as String?);
}

class PlacarResumo {
  final int casa;
  final int fora;
  PlacarResumo({required this.casa, required this.fora});

  factory PlacarResumo.fromJson(Map<String, dynamic> json) =>
      PlacarResumo(casa: json['casa'] as int, fora: json['fora'] as int);
}

class JogadorResumo {
  final String id;
  final String fullName;
  final String? nickname;
  final String? avatarUrl;
  JogadorResumo({required this.id, required this.fullName, this.nickname, this.avatarUrl});

  String get nomeExibido => (nickname != null && nickname!.trim().isNotEmpty) ? nickname! : fullName;

  factory JogadorResumo.fromJson(Map<String, dynamic> json) => JogadorResumo(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class UltimaContratacao extends JogadorResumo {
  final int? numeroCamisa;
  final DateTime? desde;
  UltimaContratacao({
    required super.id,
    required super.fullName,
    super.nickname,
    super.avatarUrl,
    this.numeroCamisa,
    this.desde,
  });

  factory UltimaContratacao.fromJson(Map<String, dynamic> json) => UltimaContratacao(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        numeroCamisa: json['numeroCamisa'] as int?,
        desde: json['desde'] != null ? DateTime.parse(json['desde'] as String) : null,
      );
}

class Artilheiro extends JogadorResumo {
  final int gols;
  Artilheiro({required super.id, required super.fullName, super.nickname, super.avatarUrl, required this.gols});

  factory Artilheiro.fromJson(Map<String, dynamic> json) => Artilheiro(
        id: json['userId'] as String,
        fullName: json['fullName'] as String,
        nickname: json['nickname'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        gols: json['gols'] as int,
      );
}

class TeamDashboard {
  final JogoResumo? proximoJogo;
  final JogoResumo? ultimoJogo;
  final UltimaContratacao? ultimaContratacao;
  final Artilheiro? artilheiro;
  final int totalJogadores;
  final int jogosRealizados;
  final int golsMarcados;

  TeamDashboard({
    this.proximoJogo,
    this.ultimoJogo,
    this.ultimaContratacao,
    this.artilheiro,
    required this.totalJogadores,
    required this.jogosRealizados,
    required this.golsMarcados,
  });

  factory TeamDashboard.fromJson(Map<String, dynamic> json) => TeamDashboard(
        proximoJogo: json['proximoJogo'] != null ? JogoResumo.fromJson(json['proximoJogo'] as Map<String, dynamic>) : null,
        ultimoJogo: json['ultimoJogo'] != null ? JogoResumo.fromJson(json['ultimoJogo'] as Map<String, dynamic>) : null,
        ultimaContratacao: json['ultimaContratacao'] != null
            ? UltimaContratacao.fromJson(json['ultimaContratacao'] as Map<String, dynamic>)
            : null,
        artilheiro: json['artilheiro'] != null ? Artilheiro.fromJson(json['artilheiro'] as Map<String, dynamic>) : null,
        totalJogadores: json['totalJogadores'] as int,
        jogosRealizados: json['jogosRealizados'] as int,
        golsMarcados: json['golsMarcados'] as int,
      );
}

import 'match_attendance.dart';
import 'match_event.dart';

/// Espelha o Match (`prisma/schema.prisma`). `attendance`/`events` só vêm
/// preenchidos no detalhe (`GET /matches/:id`); `totalConfirmados` só vem na
/// listagem (`GET /matches`, via `_count.attendance`). `homeTeamId`/
/// `awayTeamId` só existem quando o jogo nasceu de um desafio de time aceito
/// — não existe endpoint que deixe criar um jogo avulso já vinculado a um
/// time (ver auditoria da Fase 2.0).
class Match {
  final String id;
  final String createdById;
  final String? venueId;
  final String? venueName;
  final String modalidadeId;
  final String? modalidadeLabel;
  final String? homeTeamId;
  final String? homeTeamName;
  final String? homeTeamCrestUrl;
  final String? awayTeamId;
  final String? awayTeamName;
  final String? awayTeamCrestUrl;
  final DateTime scheduledAt;
  final String status;
  final int? maxPlayers;
  final String visibility;
  final int? totalConfirmados;
  final List<MatchAttendance>? attendance;
  final List<MatchEvent>? events;
  // Placar calculado pelo backend a partir dos MatchEvent tipo 'goal' — só
  // vem preenchido quando a partida tem os dois times (`temTimes`); nunca é
  // um valor digitado, nem existe coluna própria pra isso (Fase 8).
  final int? homeScore;
  final int? awayScore;
  // Se o usuário logado pode alimentar a súmula desta partida (capitão/dono
  // de um dos times, ou criador em partida avulsa) — calculado no backend.
  final bool souGestorDaSumula;
  // Valor total da quadra informado pelo gestor (nulo = não informado) e o
  // resumo da divisão calculado pelo backend (50/50 entre times, depois por jogador).
  final double? valorQuadra;
  final ResumoPagamento? resumoPagamento;
  final bool? venueCovered;
  final String? venueAddress;

  Match({
    required this.id,
    required this.createdById,
    this.venueId,
    this.venueName,
    required this.modalidadeId,
    this.modalidadeLabel,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamCrestUrl,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamCrestUrl,
    required this.scheduledAt,
    required this.status,
    this.maxPlayers,
    required this.visibility,
    this.totalConfirmados,
    this.attendance,
    this.events,
    this.homeScore,
    this.awayScore,
    this.souGestorDaSumula = false,
    this.valorQuadra,
    this.resumoPagamento,
    this.venueCovered,
    this.venueAddress,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final modalidade = json['modalidade'] as Map<String, dynamic>?;
    final venue = json['venue'] as Map<String, dynamic>?;
    final count = json['_count'] as Map<String, dynamic>?;
    final homeTeam = json['homeTeam'] as Map<String, dynamic>?;
    final awayTeam = json['awayTeam'] as Map<String, dynamic>?;
    return Match(
      id: json['id'] as String,
      createdById: json['createdById'] as String,
      venueId: json['venueId'] as String?,
      venueName: venue?['name'] as String?,
      modalidadeId: json['modalidadeId'] as String,
      modalidadeLabel: modalidade?['label'] as String?,
      homeTeamId: json['homeTeamId'] as String?,
      homeTeamName: homeTeam?['name'] as String?,
      homeTeamCrestUrl: homeTeam?['crestUrl'] as String?,
      awayTeamId: json['awayTeamId'] as String?,
      awayTeamName: awayTeam?['name'] as String?,
      awayTeamCrestUrl: awayTeam?['crestUrl'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: json['status'] as String,
      maxPlayers: json['maxPlayers'] as int?,
      visibility: json['visibility'] as String,
      totalConfirmados: count?['attendance'] as int?,
      attendance: (json['attendance'] as List?)
          ?.map((a) => MatchAttendance.fromJson(a as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List?)?.map((e) => MatchEvent.fromJson(e as Map<String, dynamic>)).toList(),
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      souGestorDaSumula: json['souGestorDaSumula'] as bool? ?? false,
      valorQuadra: (json['valorQuadra'] as num?)?.toDouble(),
      venueCovered: venue?['covered'] as bool?,
      venueAddress: venue?['address'] as String?,
      resumoPagamento: json['resumoPagamento'] == null
          ? null
          : ResumoPagamento.fromJson(json['resumoPagamento'] as Map<String, dynamic>),
    );
  }

  bool get temTimes => homeTeamId != null && awayTeamId != null;
  bool souCriador(String userId) => createdById == userId;
  bool get partidaEncerrada => status == 'finished' || status == 'cancelled';
  MatchEvent? get mvpEvento {
    final lista = events?.where((e) => e.eventType == 'mvp');
    return (lista == null || lista.isEmpty) ? null : lista.first;
  }
}

class ResumoPagamento {
  final double? totalEsperado;
  final double? totalRecebido;
  final int confirmados;
  final int pagos;
  final TotalTimePagamento? home;
  final TotalTimePagamento? away;
  final double? valorPorJogadorAvulsa;

  const ResumoPagamento({
    required this.totalEsperado,
    required this.totalRecebido,
    required this.confirmados,
    required this.pagos,
    required this.home,
    required this.away,
    required this.valorPorJogadorAvulsa,
  });

  factory ResumoPagamento.fromJson(Map<String, dynamic> json) {
    final porTime = json['porTime'] as Map<String, dynamic>?;
    final home = porTime?['home'] as Map<String, dynamic>?;
    final away = porTime?['away'] as Map<String, dynamic>?;
    return ResumoPagamento(
      totalEsperado: (json['totalEsperado'] as num?)?.toDouble(),
      totalRecebido: (json['totalRecebido'] as num?)?.toDouble(),
      confirmados: json['confirmados'] as int? ?? 0,
      pagos: json['pagos'] as int? ?? 0,
      home: home == null ? null : TotalTimePagamento.fromJson(home),
      away: away == null ? null : TotalTimePagamento.fromJson(away),
      valorPorJogadorAvulsa: (json['valorPorJogadorAvulsa'] as num?)?.toDouble(),
    );
  }
}

class TotalTimePagamento {
  final double valorTime;
  final double? valorPorJogador;
  final int jogadores;

  const TotalTimePagamento({required this.valorTime, required this.valorPorJogador, required this.jogadores});

  factory TotalTimePagamento.fromJson(Map<String, dynamic> json) {
    return TotalTimePagamento(
      valorTime: (json['valorTime'] as num).toDouble(),
      valorPorJogador: (json['valorPorJogador'] as num?)?.toDouble(),
      jogadores: json['jogadores'] as int? ?? 0,
    );
  }
}

import 'package:flutter/material.dart';
import '../matches/jogo_detail_screen.dart';
import '../matches/jogos_root_screen.dart';
import '../teams/minhas_convocacoes_screen.dart';
import '../teams/team_detail_screen.dart';
import '../venues/minha_quadra_detail_screen.dart';
import '../venues/minhas_reservas_screen.dart';

/// Resolve pra qual tela ir ao tocar numa notificação, a partir do `type` e
/// do `payload` já persistidos pelo backend (ver
/// `NotificationsService.notificar` e os call sites em
/// teams/matches/team-challenges/venues .service.ts — nenhum campo aqui foi
/// inventado, só os que esses call sites realmente gravam).
///
/// Devolve `null` quando o tipo é desconhecido ou o payload não carrega o
/// identificador necessário (ex: notificação antiga, criada antes de um
/// campo existir) — nesse caso o toque não navega pra lugar nenhum, só marca
/// como lida.
Widget? resolverDestinoDaNotificacao(String type, Map<String, dynamic> payload) {
  String? campo(String chave) => payload[chave] as String?;

  switch (type) {
    case 'team_member_added':
    case 'team_member_removed':
      final teamId = campo('teamId');
      return teamId == null ? null : TeamDetailScreen(teamId: teamId);

    case 'call_up':
      // Não existe teamId->convocação individual navegável; o destino
      // possível hoje é a própria caixa de convocações do jogador.
      return const MinhasConvocacoesScreen();

    case 'match_attendance':
    case 'match_waitlist_promoted':
      final matchId = campo('matchId');
      return matchId == null ? null : JogoDetailScreen(matchId: matchId);

    case 'challenge_accepted':
      // O desafio virou jogo de verdade no aceite — o payload já traz o
      // matchId criado, então o destino mais útil é o jogo, não o desafio.
      final matchId = campo('matchId');
      return matchId == null ? null : JogoDetailScreen(matchId: matchId);

    case 'challenge_request_received':
    case 'challenge_request_declined':
      // Não existe tela de detalhe de um TeamChallenge individual — o
      // contexto existente mais próximo é a aba Desafios.
      return const JogosRootScreen(abaInicial: 1);

    case 'booking_created':
    case 'booking_cancelled_by_renter':
      final venueId = campo('venueId');
      return venueId == null ? null : MinhaQuadraDetailScreen(venueId: venueId, abaInicial: 1);

    case 'booking_confirmed':
    case 'booking_cancelled_by_owner':
      // O payload não traz venueId — só existe a lista geral de reservas.
      return const MinhasReservasScreen();

    default:
      return null;
  }
}

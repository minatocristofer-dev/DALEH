import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/jogos_root_screen.dart';
import 'package:daleh_app/features/notifications/notification_navigator.dart';
import 'package:daleh_app/features/teams/minhas_convocacoes_screen.dart';
import 'package:daleh_app/features/teams/team_detail_screen.dart';
import 'package:daleh_app/features/venues/minha_quadra_detail_screen.dart';
import 'package:daleh_app/features/venues/minhas_reservas_screen.dart';

void main() {
  group('resolverDestinoDaNotificacao — tipos conhecidos com payload completo', () {
    test('team_member_added leva pro TeamDetailScreen do teamId certo', () {
      final destino = resolverDestinoDaNotificacao('team_member_added', {'teamId': 'time-1'});
      expect(destino, isA<TeamDetailScreen>());
      expect((destino as TeamDetailScreen).teamId, 'time-1');
    });

    test('team_member_removed leva pro TeamDetailScreen do teamId certo', () {
      final destino = resolverDestinoDaNotificacao('team_member_removed', {'teamId': 'time-2'});
      expect(destino, isA<TeamDetailScreen>());
      expect((destino as TeamDetailScreen).teamId, 'time-2');
    });

    test('call_up leva pra MinhasConvocacoesScreen (não precisa de nenhum campo do payload)', () {
      final destino = resolverDestinoDaNotificacao('call_up', {'callUpId': 'c1', 'teamId': 'time-1'});
      expect(destino, isA<MinhasConvocacoesScreen>());
    });

    test('match_attendance leva pro JogoDetailScreen do matchId certo', () {
      final destino = resolverDestinoDaNotificacao('match_attendance', {'matchId': 'jogo-1'});
      expect(destino, isA<JogoDetailScreen>());
      expect((destino as JogoDetailScreen).matchId, 'jogo-1');
    });

    test('match_waitlist_promoted leva pro JogoDetailScreen do matchId certo', () {
      final destino = resolverDestinoDaNotificacao('match_waitlist_promoted', {'matchId': 'jogo-2'});
      expect(destino, isA<JogoDetailScreen>());
      expect((destino as JogoDetailScreen).matchId, 'jogo-2');
    });

    test('challenge_accepted usa o matchId (o jogo real criado no aceite), não o challengeId', () {
      final destino = resolverDestinoDaNotificacao('challenge_accepted', {'challengeId': 'd1', 'matchId': 'jogo-3'});
      expect(destino, isA<JogoDetailScreen>());
      expect((destino as JogoDetailScreen).matchId, 'jogo-3');
    });

    test('challenge_request_received leva pro contexto de Desafios (aba índice 1)', () {
      final destino = resolverDestinoDaNotificacao('challenge_request_received', {'challengeId': 'd1', 'requestId': 'r1'});
      expect(destino, isA<JogosRootScreen>());
      expect((destino as JogosRootScreen).abaInicial, 1);
    });

    test('challenge_request_declined leva pro contexto de Desafios (aba índice 1)', () {
      final destino = resolverDestinoDaNotificacao('challenge_request_declined', {'challengeId': 'd1'});
      expect(destino, isA<JogosRootScreen>());
      expect((destino as JogosRootScreen).abaInicial, 1);
    });

    test('booking_created leva pra aba Reservas da quadra certa', () {
      final destino = resolverDestinoDaNotificacao('booking_created', {'bookingId': 'b1', 'venueId': 'v1'});
      expect(destino, isA<MinhaQuadraDetailScreen>());
      expect((destino as MinhaQuadraDetailScreen).venueId, 'v1');
      expect(destino.abaInicial, 1);
    });

    test('booking_cancelled_by_renter com venueId (payload novo, pós-correção) leva pra aba Reservas da quadra certa', () {
      final destino = resolverDestinoDaNotificacao('booking_cancelled_by_renter', {'bookingId': 'b1', 'venueId': 'v1'});
      expect(destino, isA<MinhaQuadraDetailScreen>());
      expect((destino as MinhaQuadraDetailScreen).venueId, 'v1');
    });

    test('booking_confirmed leva pra MinhasReservasScreen (payload não carrega venueId)', () {
      final destino = resolverDestinoDaNotificacao('booking_confirmed', {'bookingId': 'b1'});
      expect(destino, isA<MinhasReservasScreen>());
    });

    test('booking_cancelled_by_owner leva pra MinhasReservasScreen', () {
      final destino = resolverDestinoDaNotificacao('booking_cancelled_by_owner', {'bookingId': 'b1'});
      expect(destino, isA<MinhasReservasScreen>());
    });
  });

  group('resolverDestinoDaNotificacao — payload insuficiente/incompleto', () {
    test('booking_cancelled_by_renter SEM venueId (notificação antiga, anterior à correção) não navega', () {
      expect(resolverDestinoDaNotificacao('booking_cancelled_by_renter', {'bookingId': 'b1'}), isNull);
    });

    test('payload vazio pra um tipo que exige id não navega', () {
      expect(resolverDestinoDaNotificacao('team_member_added', {}), isNull);
      expect(resolverDestinoDaNotificacao('match_attendance', {}), isNull);
      expect(resolverDestinoDaNotificacao('challenge_accepted', {}), isNull);
      expect(resolverDestinoDaNotificacao('booking_created', {'bookingId': 'b1'}), isNull);
    });

    test('payload incompleto (com outros campos, mas sem o necessário) não navega', () {
      expect(resolverDestinoDaNotificacao('match_attendance', {'outroCampo': 'x'}), isNull);
    });
  });

  group('resolverDestinoDaNotificacao — tipo desconhecido', () {
    test('tipo que não existe em nenhum call site do backend não navega', () {
      expect(resolverDestinoDaNotificacao('tipo_que_nao_existe', {'qualquer': 'coisa'}), isNull);
    });
  });
}

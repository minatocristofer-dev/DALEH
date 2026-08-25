import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/matches/models/challenge_request.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/matches/models/match_attendance.dart';
import 'package:daleh_app/features/matches/models/match_event.dart';
import 'package:daleh_app/features/matches/models/meus_desafios.dart';
import 'package:daleh_app/features/matches/models/team_challenge.dart';

void main() {
  group('Match.fromJson', () {
    test('lê jogo avulso, sem times vinculados', () {
      final partida = Match.fromJson({
        'id': 'match-1',
        'createdById': 'user-1',
        'venueId': null,
        'modalidadeId': 'modalidade-1',
        'modalidade': {'id': 'modalidade-1', 'key': 'SOCIETY', 'label': 'Society'},
        'venue': null,
        'homeTeamId': null,
        'awayTeamId': null,
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'scheduled',
        'maxPlayers': 10,
        'visibility': 'public',
      });

      expect(partida.modalidadeLabel, 'Society');
      expect(partida.temTimes, isFalse);
      expect(partida.souCriador('user-1'), isTrue);
    });

    test('lê jogo nascido de um desafio de time, com nomes dos times', () {
      final partida = Match.fromJson({
        'id': 'match-2',
        'createdById': 'user-1',
        'venueId': null,
        'modalidadeId': 'modalidade-1',
        'homeTeamId': 'time-a',
        'homeTeam': {'id': 'time-a', 'name': 'Time A', 'crestUrl': null},
        'awayTeamId': 'time-b',
        'awayTeam': {'id': 'time-b', 'name': 'Time B', 'crestUrl': null},
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'scheduled',
        'visibility': 'public',
      });

      expect(partida.temTimes, isTrue);
      expect(partida.homeTeamName, 'Time A');
      expect(partida.awayTeamName, 'Time B');
    });

    test('lê _count.attendance só presente na listagem', () {
      final partida = Match.fromJson({
        'id': 'match-3',
        'createdById': 'user-1',
        'modalidadeId': 'modalidade-1',
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'scheduled',
        'visibility': 'public',
        '_count': {'attendance': 7},
      });

      expect(partida.totalConfirmados, 7);
    });

    test('lê placar calculado e permissão de gestão da súmula (Fase 8)', () {
      final partida = Match.fromJson({
        'id': 'match-4',
        'createdById': 'user-1',
        'modalidadeId': 'modalidade-1',
        'homeTeamId': 'time-a',
        'awayTeamId': 'time-b',
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'finished',
        'visibility': 'public',
        'homeScore': 3,
        'awayScore': 2,
        'souGestorDaSumula': true,
        'events': [
          {
            'id': 'e1',
            'matchId': 'match-4',
            'userId': 'user-mvp',
            'eventType': 'mvp',
            'createdAt': '2026-09-10T21:00:00.000Z',
            'user': {'id': 'user-mvp', 'fullName': 'João'},
          },
        ],
      });

      expect(partida.homeScore, 3);
      expect(partida.awayScore, 2);
      expect(partida.souGestorDaSumula, isTrue);
      expect(partida.partidaEncerrada, isTrue);
      expect(partida.mvpEvento?.userFullName, 'João');
    });

    test('souGestorDaSumula é false por padrão quando o backend não manda o campo', () {
      final partida = Match.fromJson({
        'id': 'match-5',
        'createdById': 'user-1',
        'modalidadeId': 'modalidade-1',
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'scheduled',
        'visibility': 'public',
      });

      expect(partida.souGestorDaSumula, isFalse);
      expect(partida.homeScore, isNull);
      expect(partida.mvpEvento, isNull);
      expect(partida.partidaEncerrada, isFalse);
    });
  });

  group('MatchEvent.fromJson', () {
    test('lê o nome/avatar de quem fez o evento e o teamId congelado (Fase 9), quando o backend inclui', () {
      final evento = MatchEvent.fromJson({
        'id': 'e1',
        'matchId': 'match-1',
        'userId': 'user-1',
        'teamId': 'time-a',
        'eventType': 'goal',
        'minute': null,
        'createdAt': '2026-09-10T21:05:00.000Z',
        'user': {'id': 'user-1', 'fullName': 'Pedro', 'avatarUrl': null},
      });

      expect(evento.userFullName, 'Pedro');
      expect(evento.teamId, 'time-a');
      expect(evento.createdAt, DateTime.parse('2026-09-10T21:05:00.000Z'));
    });

    test('lida bem sem o campo user e sem teamId (evento antigo, pré-Fase 9, não migrável com segurança)', () {
      final evento = MatchEvent.fromJson({
        'id': 'e1',
        'matchId': 'match-1',
        'userId': 'user-1',
        'eventType': 'yellow',
        'createdAt': '2026-08-25T00:00:00.000Z',
      });

      expect(evento.userFullName, isNull);
      expect(evento.teamId, isNull);
    });
  });

  group('MatchAttendance.fromJson', () {
    test('classifica confirmado vs lista de espera', () {
      final confirmado = MatchAttendance.fromJson({
        'id': 'a1',
        'matchId': 'match-1',
        'userId': 'user-1',
        'status': 'confirmed',
        'createdAt': '2026-08-21T00:00:00.000Z',
        'user': {'id': 'user-1', 'fullName': 'Jogador', 'avatarUrl': null},
      });
      final espera = MatchAttendance.fromJson({
        'id': 'a2',
        'matchId': 'match-1',
        'userId': 'user-2',
        'status': 'waitlist',
        'createdAt': '2026-08-21T00:01:00.000Z',
      });

      expect(confirmado.confirmado, isTrue);
      expect(confirmado.userFullName, 'Jogador');
      expect(espera.naEspera, isTrue);
    });

    test('lê teamId e posicaoPrincipal da escalação (Fase visual) quando presentes', () {
      final comEscalacao = MatchAttendance.fromJson({
        'id': 'a1',
        'matchId': 'match-1',
        'userId': 'user-1',
        'status': 'confirmed',
        'createdAt': '2026-08-21T00:00:00.000Z',
        'teamId': 'time-a',
        'posicaoPrincipal': 'Atacante',
        'user': {'id': 'user-1', 'fullName': 'Jogador', 'avatarUrl': null},
      });
      final semEscalacao = MatchAttendance.fromJson({
        'id': 'a2',
        'matchId': 'match-1',
        'userId': 'user-2',
        'status': 'confirmed',
        'createdAt': '2026-08-21T00:00:00.000Z',
      });

      expect(comEscalacao.teamId, 'time-a');
      expect(comEscalacao.posicaoPrincipal, 'Atacante');
      expect(semEscalacao.teamId, isNull);
      expect(semEscalacao.posicaoPrincipal, isNull);
    });
  });

  group('TeamChallenge / ChallengeRequest', () {
    test('TeamChallenge.fromJson lê o formato de listarDesafios (com team, sem requests)', () {
      final desafio = TeamChallenge.fromJson({
        'id': 'desafio-1',
        'teamId': 'time-a',
        'team': {'id': 'time-a', 'name': 'Time A', 'crestUrl': null},
        'city': 'Santa Maria',
        'scheduledDate': '2026-09-15T00:00:00.000Z',
        'scheduledTime': '19:30',
        'desiredLevel': 'intermediario',
        'status': 'ABERTA',
      });

      expect(desafio.teamName, 'Time A');
      expect(desafio.aberta, isTrue);
      expect(desafio.requests, isEmpty);
    });

    test('TeamChallenge.fromJson lê comoOrganizador (com requests+requestingTeam)', () {
      final desafio = TeamChallenge.fromJson({
        'id': 'desafio-1',
        'teamId': 'time-a',
        'city': 'Santa Maria',
        'scheduledDate': '2026-09-15T00:00:00.000Z',
        'scheduledTime': '19:30',
        'desiredLevel': 'intermediario',
        'status': 'ABERTA',
        'requests': [
          {
            'id': 'req-1',
            'challengeId': 'desafio-1',
            'requestingTeamId': 'time-b',
            'status': 'PENDENTE',
            'createdAt': '2026-08-21T00:00:00.000Z',
            'requestingTeam': {'id': 'time-b', 'name': 'Time B', 'crestUrl': null},
          },
        ],
      });

      expect(desafio.requests, hasLength(1));
      expect(desafio.requests.first.requestingTeamName, 'Time B');
      expect(desafio.requests.first.pendente, isTrue);
    });

    test('ChallengeRequest.fromJson lê minhasSolicitacoes (com challenge+team, sem requestingTeam)', () {
      final solicitacao = ChallengeRequest.fromJson({
        'id': 'req-1',
        'challengeId': 'desafio-1',
        'requestingTeamId': 'time-b',
        'status': 'ACEITA',
        'createdAt': '2026-08-21T00:00:00.000Z',
        'challenge': {
          'city': 'Santa Maria',
          'scheduledDate': '2026-09-15T00:00:00.000Z',
          'scheduledTime': '19:30',
          'status': 'CONFIRMADA',
          'team': {'id': 'time-a', 'name': 'Time A', 'crestUrl': null},
        },
      });

      expect(solicitacao.requestingTeamName, isNull);
      expect(solicitacao.challengeOrganizerTeamName, 'Time A');
      expect(solicitacao.challengeCity, 'Santa Maria');
    });
  });

  group('MeusDesafios.fromJson', () {
    test('separa comoOrganizador e minhasSolicitacoes', () {
      final meus = MeusDesafios.fromJson({
        'comoOrganizador': [
          {
            'id': 'd1',
            'teamId': 't1',
            'city': 'Santa Maria',
            'scheduledDate': '2026-09-15T00:00:00.000Z',
            'scheduledTime': '19:30',
            'desiredLevel': 'intermediario',
            'status': 'ABERTA',
          },
        ],
        'minhasSolicitacoes': [],
      });

      expect(meus.comoOrganizador, hasLength(1));
      expect(meus.minhasSolicitacoes, isEmpty);
    });
  });
}

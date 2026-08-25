import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/teams/models/call_up.dart';
import 'package:daleh_app/features/teams/models/team.dart';
import 'package:daleh_app/features/teams/models/team_member.dart';
import 'package:daleh_app/features/notifications/models/app_notification.dart';

void main() {
  group('Team.fromJson', () {
    test('lê os campos de GET /teams/mine, incluindo meuPapel e totalMembros', () {
      final time = Team.fromJson({
        'id': 'time-1',
        'name': 'DALEH FC',
        'crestUrl': null,
        'city': 'Santa Maria',
        'state': 'RS',
        'ownerId': 'user-dono',
        'meuPapel': 'CAPITAO',
        'totalMembros': 12,
      });

      expect(time.name, 'DALEH FC');
      expect(time.meuPapel, 'CAPITAO');
      expect(time.totalMembros, 12);
      expect(time.souDono('user-dono'), isTrue);
      expect(time.souDono('outro-usuario'), isFalse);
    });

    test('lê o retorno cru de POST /teams, sem meuPapel/totalMembros', () {
      final time = Team.fromJson({
        'id': 'time-2',
        'name': 'Novo Time',
        'crestUrl': null,
        'city': null,
        'state': null,
        'ownerId': 'user-dono',
      });

      expect(time.meuPapel, isNull);
      expect(time.totalMembros, isNull);
    });
  });

  group('TeamDetail', () {
    final detailJson = {
      'id': 'time-1',
      'name': 'DALEH FC',
      'crestUrl': null,
      'city': 'Santa Maria',
      'state': 'RS',
      'ownerId': 'user-dono',
      'members': [
        {
          'id': 'm1',
          'teamId': 'time-1',
          'userId': 'user-dono',
          'papel': 'CAPITAO',
          'status': 'active',
          'user': {'id': 'user-dono', 'fullName': 'Dono', 'avatarUrl': null},
        },
        {
          'id': 'm2',
          'teamId': 'time-1',
          'userId': 'user-jogador',
          'papel': 'JOGADOR',
          'status': 'active',
          'user': {'id': 'user-jogador', 'fullName': 'Jogador', 'avatarUrl': null},
        },
        {
          'id': 'm3',
          'teamId': 'time-1',
          'userId': 'user-vice',
          'papel': 'VICE_CAPITAO',
          'status': 'active',
          'user': {'id': 'user-vice', 'fullName': 'Vice', 'avatarUrl': null},
        },
      ],
    };

    test('dono pode gerenciar mesmo sem estar em papeisDeGestao explicitamente', () {
      final detail = TeamDetail.fromJson(detailJson);
      expect(detail.possoGerenciar('user-dono'), isTrue);
    });

    test('capitão e vice-capitão podem gerenciar', () {
      final detail = TeamDetail.fromJson(detailJson);
      expect(detail.possoGerenciar('user-vice'), isTrue);
    });

    test('jogador comum não pode gerenciar', () {
      final detail = TeamDetail.fromJson(detailJson);
      expect(detail.possoGerenciar('user-jogador'), isFalse);
    });

    test('usuário fora do elenco não pode gerenciar', () {
      final detail = TeamDetail.fromJson(detailJson);
      expect(detail.possoGerenciar('user-estranho'), isFalse);
    });

    test('membroPor encontra o membro certo pelo userId', () {
      final detail = TeamDetail.fromJson(detailJson);
      expect(detail.membroPor('user-jogador')?.fullName, 'Jogador');
      expect(detail.membroPor('nao-existe'), isNull);
    });
  });

  group('TeamMember.estatisticas (Fase visual)', () {
    test('lê jogos/gols/mvp reais quando o backend devolve o campo estatisticas', () {
      final membro = TeamMember.fromJson({
        'id': 'm1',
        'teamId': 'time-1',
        'userId': 'user-1',
        'papel': 'JOGADOR',
        'status': 'active',
        'user': {'id': 'user-1', 'fullName': 'Jogador', 'avatarUrl': null},
        'estatisticas': {'jogos': 8, 'gols': 3, 'mvp': 1},
      });

      expect(membro.estatisticas.jogos, 8);
      expect(membro.estatisticas.gols, 3);
      expect(membro.estatisticas.mvp, 1);
    });

    test('sem o campo estatisticas no JSON, fica zerado — nunca null ou inventado', () {
      final membro = TeamMember.fromJson({
        'id': 'm1',
        'teamId': 'time-1',
        'userId': 'user-1',
        'papel': 'JOGADOR',
        'status': 'active',
        'user': {'id': 'user-1', 'fullName': 'Jogador', 'avatarUrl': null},
      });

      expect(membro.estatisticas.jogos, 0);
      expect(membro.estatisticas.gols, 0);
      expect(membro.estatisticas.mvp, 0);
    });
  });

  group('CallUp.fromJson', () {
    test('lê o formato de GET /call-ups/mine (com team, sem user)', () {
      final callUp = CallUp.fromJson({
        'id': 'callup-1',
        'teamId': 'time-1',
        'matchId': null,
        'userId': 'user-1',
        'venueNameSnapshot': 'Arena Teste',
        'scheduledDate': '2026-09-10T00:00:00.000Z',
        'scheduledTime': '20:00',
        'status': 'PENDENTE',
        'respondedAt': null,
        'createdAt': '2026-08-21T03:08:27.908Z',
        'team': {'id': 'time-1', 'name': 'DALEH FC', 'crestUrl': null},
      });

      expect(callUp.teamName, 'DALEH FC');
      expect(callUp.userFullName, isNull);
      expect(callUp.pendente, isTrue);
      expect(callUp.confirmado, isFalse);
    });

    test('lê o formato de GET /teams/:id/call-ups (com user, sem team)', () {
      final callUp = CallUp.fromJson({
        'id': 'callup-2',
        'teamId': 'time-1',
        'matchId': null,
        'userId': 'user-1',
        'venueNameSnapshot': 'Arena Teste',
        'scheduledDate': '2026-09-10T00:00:00.000Z',
        'scheduledTime': '20:00',
        'status': 'CONFIRMADO',
        'respondedAt': '2026-08-21T03:08:34.406Z',
        'createdAt': '2026-08-21T03:08:27.908Z',
        'user': {'id': 'user-1', 'fullName': 'Jogador Teste'},
      });

      expect(callUp.teamName, isNull);
      expect(callUp.userFullName, 'Jogador Teste');
      expect(callUp.confirmado, isTrue);
    });
  });

  group('AppNotification.fromJson', () {
    test('lê titulo/corpo de dentro do payload', () {
      final n = AppNotification.fromJson({
        'id': 'notif-1',
        'type': 'team_member_added',
        'payload': {'titulo': 'Novo time', 'corpo': 'Você entrou no time DALEH FC.', 'teamId': 'time-1'},
        'readAt': null,
        'createdAt': '2026-08-21T03:08:21.334Z',
      });

      expect(n.titulo, 'Novo time');
      expect(n.corpo, 'Você entrou no time DALEH FC.');
      expect(n.lida, isFalse);
      expect(n.payload['teamId'], 'time-1');
    });

    test('cai num texto genérico se titulo/corpo faltarem no payload', () {
      final n = AppNotification.fromJson({
        'id': 'notif-2',
        'type': 'algo_novo',
        'payload': <String, dynamic>{},
        'readAt': '2026-08-21T04:00:00.000Z',
        'createdAt': '2026-08-21T03:08:21.334Z',
      });

      expect(n.titulo, 'Notificação');
      expect(n.corpo, '');
      expect(n.lida, isTrue);
    });
  });
}

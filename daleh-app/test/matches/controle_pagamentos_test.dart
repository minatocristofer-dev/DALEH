import 'package:daleh_app/features/matches/controle_pagamentos_tab.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/matches/models/match_attendance.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _presenca(String userId, String nome, {String status = 'confirmed', String? pagoEm}) => {
      'id': 'att-$userId',
      'matchId': 'm1',
      'userId': userId,
      'status': status,
      'createdAt': '2026-10-01T10:00:00.000Z',
      'pagoEm': pagoEm,
      'user': {'id': userId, 'fullName': nome, 'avatarUrl': null},
    };

Match _partida({required bool gestor, required List<Map<String, dynamic>> attendance}) {
  return Match.fromJson({
    'id': 'm1',
    'createdById': 'criador',
    'modalidadeId': 'mod-futsal',
    'scheduledAt': '2026-10-10T20:00:00.000Z',
    'status': 'scheduled',
    'visibility': 'public',
    'souGestorDaSumula': gestor,
    'attendance': attendance,
    'events': [],
  });
}

Widget _tela(Match partida) => ProviderScope(
      child: MaterialApp(
        theme: buildDalehTheme(),
        home: Scaffold(body: ControlePagamentosTab(partida: partida)),
      ),
    );

void main() {
  group('MatchAttendance.pagoEm', () {
    test('nulo quando não pagou, e pago=true quando há data', () {
      final pendente = MatchAttendance.fromJson(_presenca('a', 'Ana'));
      final pago = MatchAttendance.fromJson(_presenca('b', 'Bia', pagoEm: '2026-10-05T12:00:00.000Z'));

      expect(pendente.pago, isFalse);
      expect(pendente.pagoEm, isNull);
      expect(pago.pago, isTrue);
      expect(pago.pagoEm, DateTime.parse('2026-10-05T12:00:00.000Z'));
    });
  });

  testWidgets('mostra o resumo "X/Y pagaram" contando só confirmados', (tester) async {
    final partida = _partida(gestor: true, attendance: [
      _presenca('a', 'Ana', pagoEm: '2026-10-05T12:00:00.000Z'),
      _presenca('b', 'Bia'),
      _presenca('c', 'Caio'),
      _presenca('d', 'Dani', status: 'waitlist'),
    ]);

    await tester.pumpWidget(_tela(partida));

    expect(find.text('1/3 pagaram'), findsOneWidget);
    expect(find.text('Pago'), findsOneWidget);
    expect(find.text('Pendente'), findsNWidgets(2));
    expect(find.text('Dani'), findsNothing, reason: 'lista de espera não entra no controle');
  });

  testWidgets('gestor vê o "\$" tocável; jogador comum não consegue alterar', (tester) async {
    final gestor = _partida(gestor: true, attendance: [_presenca('a', 'Ana')]);
    await tester.pumpWidget(_tela(gestor));
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('\$').first, matching: find.byType(InkWell))).onTap, isNotNull);

    final jogador = _partida(gestor: false, attendance: [_presenca('a', 'Ana')]);
    await tester.pumpWidget(_tela(jogador));
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(find.ancestor(of: find.text('\$').first, matching: find.byType(InkWell))).onTap, isNull);
    expect(find.text('Só o organizador da partida pode marcar pagamentos.'), findsOneWidget);
  });

  testWidgets('com valor da quadra: mostra total, divisão por time e valor devido de cada jogador', (tester) async {
    final partida = Match.fromJson({
      'id': 'm1',
      'createdById': 'criador',
      'modalidadeId': 'mod-society',
      'scheduledAt': '2026-10-10T20:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
      'homeTeamId': 'casa',
      'awayTeamId': 'fora',
      'homeTeam': {'id': 'casa', 'name': 'Casa FC', 'crestUrl': null},
      'awayTeam': {'id': 'fora', 'name': 'Fora FC', 'crestUrl': null},
      'souGestorDaSumula': true,
      'valorQuadra': 200,
      'resumoPagamento': {
        'valorQuadra': 200,
        'totalEsperado': 200,
        'totalRecebido': 20,
        'confirmados': 2,
        'pagos': 1,
        'porTime': {
          'home': {'valorTime': 100, 'valorPorJogador': 100, 'jogadores': 1},
          'away': {'valorTime': 100, 'valorPorJogador': null, 'jogadores': 0},
        },
        'valorPorJogadorAvulsa': null,
      },
      'attendance': [
        {..._presenca('a', 'Ana', pagoEm: '2026-10-05T12:00:00.000Z'), 'teamId': 'casa', 'valorDevido': 100},
        {..._presenca('b', 'Bia'), 'teamId': 'casa', 'valorDevido': 100},
      ],
      'events': [],
    });

    await tester.pumpWidget(_tela(partida));

    expect(find.text('Quadra R\$ 200,00'), findsOneWidget);
    expect(find.text('Recebido R\$ 20,00 de R\$ 200,00'), findsOneWidget);
    expect(find.text('Casa FC: R\$ 100,00 · R\$ 100,00 por jogador (1)'), findsOneWidget);
    expect(find.text('R\$ 100,00'), findsNWidgets(2));
    expect(find.text('1/2 pagaram'), findsOneWidget);
  });

  testWidgets('sem valor informado, gestor vê o convite pra informar e jogador vê só o aviso', (tester) async {
    await tester.pumpWidget(_tela(_partida(gestor: true, attendance: [_presenca('a', 'Ana')])));
    expect(find.text('Informar valor'), findsOneWidget);

    await tester.pumpWidget(_tela(_partida(gestor: false, attendance: [_presenca('a', 'Ana')])));
    await tester.pumpAndSettle();
    expect(find.text('O valor da quadra ainda não foi informado.'), findsOneWidget);
    expect(find.text('Informar valor'), findsNothing);
  });

  testWidgets('sem confirmados mostra estado vazio sem crashar', (tester) async {
    await tester.pumpWidget(_tela(_partida(gestor: true, attendance: [])));
    expect(find.text('Nenhum jogador confirmado ainda.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

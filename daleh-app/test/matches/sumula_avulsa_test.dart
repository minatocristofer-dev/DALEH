import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/matches_providers.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/matches/models/match_event.dart';
import 'package:daleh_app/features/teams/teams_providers.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _evento(String id, String tipo, {String? lado, required String nome, required String criadoEm}) => {
      'id': id,
      'matchId': 'm1',
      'userId': 'u-$id',
      'eventType': tipo,
      'lado': lado,
      'minute': 10,
      'createdAt': criadoEm,
      'user': {'id': 'u-$id', 'fullName': nome, 'avatarUrl': null},
    };

Match _avulsa({required List<Map<String, dynamic>> eventos}) => Match.fromJson({
      'id': 'm1',
      'createdById': 'criador',
      'modalidadeId': 'mod-society',
      'scheduledAt': '2026-10-10T20:00:00.000Z',
      'status': 'in_progress',
      'visibility': 'public',
      'souGestorDaSumula': true,
      'attendance': [],
      'events': eventos,
    });

Widget _tela(Match partida) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        partidaDetalheProvider('m1').overrideWith((ref) async => partida),
        meuUserIdProvider.overrideWith((ref) => 'criador'),
      ],
      child: MaterialApp(
        theme: buildDalehTheme(),
        home: const JogoDetailScreen(matchId: 'm1'),
      ),
    );

void main() {
  test('MatchEvent lê o lado do placar (A ou B) e aceita ausência', () {
    final com = MatchEvent.fromJson(_evento('1', 'goal', lado: 'B', nome: 'Ana', criadoEm: '2026-10-10T20:01:00.000Z'));
    final sem = MatchEvent.fromJson(_evento('2', 'goal', nome: 'Ana', criadoEm: '2026-10-10T20:02:00.000Z'));
    expect(com.lado, 'B');
    expect(sem.lado, isNull);
  });

  testWidgets('partida avulsa: placar vem dos gols com lado e cada evento cai na coluna do seu lado', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final partida = Match.fromJson({
      'id': 'm1',
      'createdById': 'criador',
      'modalidadeId': 'mod-society',
      'scheduledAt': '2026-10-10T20:00:00.000Z',
      'status': 'in_progress',
      'visibility': 'public',
      'souGestorDaSumula': true,
      'attendance': [],
      'homeScore': 2,
      'awayScore': 1,
      'events': [
        _evento('1', 'goal', lado: 'A', nome: 'Ana', criadoEm: '2026-10-10T20:01:00.000Z'),
        _evento('2', 'goal', lado: 'B', nome: 'Bia', criadoEm: '2026-10-10T20:02:00.000Z'),
        _evento('3', 'goal', lado: 'A', nome: 'Caio', criadoEm: '2026-10-10T20:03:00.000Z'),
        _evento('4', 'yellow', lado: 'B', nome: 'Dani', criadoEm: '2026-10-10T20:04:00.000Z'),
      ],
    });

    await tester.pumpWidget(_tela(partida));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('2 × 1'), findsNWidgets(2));
    expect(find.text('Time A'), findsWidgets);
    expect(find.text('Time B'), findsWidgets);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Dani'), findsOneWidget);
    expect(find.text('CARTÃO AMARELO'), findsOneWidget);
    expect(find.text('Registrar evento'), findsOneWidget);
  });

  testWidgets('evento de avulsa sem lado aparece no aviso, não some', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_tela(_avulsa(eventos: [
      _evento('1', 'yellow', nome: 'Eva', criadoEm: '2026-10-10T20:01:00.000Z'),
    ])));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('1 evento(s) sem lado definido'), findsOneWidget);
  });
}

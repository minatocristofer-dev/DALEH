import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/shared/widgets/match_card.dart';
import 'package:daleh_app/theme/daleh_theme.dart';

Widget _comTema(Widget filho) => MaterialApp(theme: buildDalehTheme(), home: Scaffold(body: filho));

void main() {
  testWidgets('mostra modalidade quando o jogo é avulso (sem times)', (tester) async {
    final partida = Match.fromJson({
      'id': 'm1',
      'createdById': 'user-1',
      'modalidadeId': 'mod-1',
      'modalidade': {'id': 'mod-1', 'key': 'SOCIETY', 'label': 'Society'},
      'scheduledAt': '2026-09-10T20:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
      '_count': {'attendance': 4},
    });

    await tester.pumpWidget(_comTema(MatchCard(partida: partida, onTap: () {})));

    expect(find.text('Society'), findsOneWidget);
    expect(find.text('4 confirmados'), findsOneWidget);
  });

  testWidgets('mostra "Time A x Time B" quando o jogo nasceu de um desafio', (tester) async {
    var tocou = false;
    final partida = Match.fromJson({
      'id': 'm2',
      'createdById': 'user-1',
      'modalidadeId': 'mod-1',
      'homeTeamId': 'ta',
      'homeTeam': {'id': 'ta', 'name': 'DALEH FC', 'crestUrl': null},
      'awayTeamId': 'tb',
      'awayTeam': {'id': 'tb', 'name': 'Amigos do Zé', 'crestUrl': null},
      'scheduledAt': '2026-09-10T20:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
    });

    await tester.pumpWidget(_comTema(MatchCard(partida: partida, onTap: () => tocou = true)));

    expect(find.text('DALEH FC x Amigos do Zé'), findsOneWidget);
    await tester.tap(find.byType(MatchCard));
    expect(tocou, isTrue);
  });

  testWidgets('mostra o placar real quando a partida já tem gols (fechamento MVP — histórico em "Meus Jogos")', (tester) async {
    final partida = Match.fromJson({
      'id': 'm3',
      'createdById': 'user-1',
      'modalidadeId': 'mod-1',
      'homeTeamId': 'ta',
      'homeTeam': {'id': 'ta', 'name': 'DALEH FC', 'crestUrl': null},
      'awayTeamId': 'tb',
      'awayTeam': {'id': 'tb', 'name': 'Amigos do Zé', 'crestUrl': null},
      'scheduledAt': '2026-09-10T20:00:00.000Z',
      'status': 'finished',
      'visibility': 'public',
      'homeScore': 3,
      'awayScore': 1,
    });

    await tester.pumpWidget(_comTema(MatchCard(partida: partida, onTap: () {})));

    expect(find.text('3 × 1'), findsOneWidget);
  });

  testWidgets('sem placar calculado ainda, não mostra nenhum número inventado', (tester) async {
    final partida = Match.fromJson({
      'id': 'm4',
      'createdById': 'user-1',
      'modalidadeId': 'mod-1',
      'homeTeamId': 'ta',
      'homeTeam': {'id': 'ta', 'name': 'DALEH FC', 'crestUrl': null},
      'awayTeamId': 'tb',
      'awayTeam': {'id': 'tb', 'name': 'Amigos do Zé', 'crestUrl': null},
      'scheduledAt': '2026-09-10T20:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
    });

    await tester.pumpWidget(_comTema(MatchCard(partida: partida, onTap: () {})));

    expect(find.textContaining('×'), findsNothing);
  });
}

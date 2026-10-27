import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/matches/models/match_attendance.dart';
import 'package:daleh_app/features/matches/models/match_event.dart';
import 'package:daleh_app/features/matches/sumula_widgets.dart';

// QA Round 3, item 16 — "share view renderiza": os 3 cards novos de
// compartilhamento (súmula, escalação, confronto da quadra) precisam
// renderizar sem crashar com dado real, mesmo sem tocar em `compartilharImagem`
// (que depende de plugins de plataforma indisponíveis em teste de widget).

Match _partidaComTimes({MatchEvent? mvpEvento}) => Match(
      id: 'm1',
      createdById: 'u1',
      modalidadeId: 'mod1',
      homeTeamId: 'home',
      homeTeamName: 'Falcões FC',
      awayTeamId: 'away',
      awayTeamName: 'Águias FC',
      scheduledAt: DateTime(2026, 10, 20, 20),
      status: 'finished',
      visibility: 'public',
      homeScore: 2,
      awayScore: 1,
      events: [
        if (mvpEvento != null) mvpEvento,
      ],
    );

MatchEvent _gol({required String id, required String userId, String? nome, String? teamId, int? minuto}) => MatchEvent(
      id: id,
      matchId: 'm1',
      userId: userId,
      eventType: 'goal',
      minute: minuto,
      userFullName: nome,
      teamId: teamId,
      createdAt: DateTime(2026, 10, 20, 20, minuto ?? 0),
    );

void main() {
  testWidgets('SumulaShareCard renderiza placar, gols e MVP sem crashar', (tester) async {
    final mvp = MatchEvent(
      id: 'mvp1',
      matchId: 'm1',
      userId: 'u2',
      eventType: 'mvp',
      userFullName: 'Carlos',
      createdAt: DateTime(2026, 10, 20, 21),
    );
    final partida = _partidaComTimes(mvpEvento: mvp);
    final eventos = [
      EventoComPlacar(evento: _gol(id: 'g1', userId: 'u2', nome: 'Carlos', teamId: 'home', minuto: 10), placarNoMomento: '1 × 0'),
      EventoComPlacar(evento: _gol(id: 'g2', userId: 'u3', nome: 'Diego', teamId: 'away', minuto: 30), placarNoMomento: '1 × 1'),
    ];

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SumulaShareCard(partida: partida, eventos: eventos))));
    await tester.pumpAndSettle();

    expect(find.text('Falcões FC'), findsOneWidget);
    expect(find.text('Águias FC'), findsOneWidget);
    expect(find.text('2 × 1'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Diego'), findsOneWidget);
    expect(find.textContaining('MVP: Carlos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EscalacaoShareCard agrupa confirmados por time e por posição sem crashar', (tester) async {
    final partida = _partidaComTimes();
    final confirmados = [
      MatchAttendance(
        id: 'a1',
        matchId: 'm1',
        userId: 'u1',
        status: 'confirmed',
        createdAt: DateTime(2026, 10, 20),
        userFullName: 'Carlos',
        teamId: 'home',
        posicaoPrincipal: 'Goleiro',
      ),
      MatchAttendance(
        id: 'a2',
        matchId: 'm1',
        userId: 'u2',
        status: 'confirmed',
        createdAt: DateTime(2026, 10, 20),
        userFullName: 'Diego',
        teamId: 'away',
        posicaoPrincipal: 'Atacante',
      ),
    ];

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: EscalacaoShareCard(partida: partida, confirmados: confirmados))));
    await tester.pumpAndSettle();

    expect(find.text('Falcões FC × Águias FC'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Diego'), findsOneWidget);
    expect(find.text('GOLEIROS'), findsOneWidget);
    expect(find.text('ATACANTES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

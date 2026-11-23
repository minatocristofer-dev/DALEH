import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/matches/convocados_share_card.dart';
import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/matches/models/match_attendance.dart';
import 'package:daleh_app/features/matches/models/match_event.dart';
import 'package:daleh_app/features/matches/sumula_widgets.dart';

// QA Round 3, item 16 — "share view renderiza": os cards novos de
// compartilhamento (súmula, convocados) precisam renderizar sem crashar com
// dado real, mesmo sem tocar em `compartilharImagem` (que depende de plugins
// de plataforma indisponíveis em teste de widget).

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

  MatchAttendance _presenca({
    required String id,
    required String nome,
    String? teamId,
    String? posicao,
    int? numero,
  }) =>
      MatchAttendance(
        id: id,
        matchId: 'm1',
        userId: id,
        status: 'confirmed',
        createdAt: DateTime(2026, 10, 20),
        userFullName: nome,
        teamId: teamId,
        posicaoPrincipal: posicao,
        numeroCamisa: numero,
      );

  Widget _hospedar(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('ConvocadosShareCard', () {
    testWidgets('com dois times: mostra nomes dos dois times (confronto real), não "A vs B" fixo', (tester) async {
      final partida = _partidaComTimes();
      final confirmados = [
        _presenca(id: 'u1', nome: 'Carlos', teamId: 'home', posicao: 'Goleiro', numero: 1),
        _presenca(id: 'u2', nome: 'Diego', teamId: 'away', posicao: 'Atacante', numero: 9),
      ];

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: confirmados)));
      await tester.pumpAndSettle();

      expect(find.text('Falcões FC'), findsOneWidget);
      expect(find.text('Águias FC'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('CONVOCADOS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // contador de confirmados
      expect(find.text('Carlos'), findsOneWidget);
      expect(find.text('Diego'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('GOLEIRO'), findsOneWidget);
      expect(find.text('ATACANTE'), findsOneWidget);
      // Nunca deve existir separação visual por time (regra: lista única).
      expect(find.text('Falcões FC × Águias FC'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem times vinculados: usa fallback de modalidade, nunca inventa confronto', (tester) async {
      final partida = Match(
        id: 'm2',
        createdById: 'u1',
        modalidadeId: 'mod1',
        modalidadeLabel: 'Futsal',
        scheduledAt: DateTime(2026, 10, 20, 20),
        status: 'scheduled',
        visibility: 'public',
      );
      final confirmados = [_presenca(id: 'u1', nome: 'Jean')];

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: confirmados)));
      await tester.pumpAndSettle();

      expect(find.text('Futsal'), findsOneWidget);
      expect(find.text('VS'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lista vazia: não crasha e mostra contador zero', (tester) async {
      final partida = _partidaComTimes();

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: const [])));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Ninguém confirmado ainda.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem número de camisa e sem posição: oculta sem quebrar o layout', (tester) async {
      final partida = _partidaComTimes();
      final confirmados = [_presenca(id: 'u1', nome: 'Jogador Sem Dados')];

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: confirmados)));
      await tester.pumpAndSettle();

      expect(find.text('Jogador Sem Dados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nomes longos recebem elipse em vez de estourar o layout', (tester) async {
      final partida = _partidaComTimes();
      final confirmados = [
        _presenca(id: 'u1', nome: 'Jose Francisco de Assis Nascimento Oliveira Junior da Silva Santos'),
      ];

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: confirmados)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('25 confirmados: nenhum é ocultado silenciosamente', (tester) async {
      final partida = _partidaComTimes();
      final confirmados = List.generate(25, (i) => _presenca(id: 'u$i', nome: 'Jogador $i'));

      await tester.pumpWidget(_hospedar(ConvocadosShareCard(partida: partida, confirmados: confirmados)));
      await tester.pumpAndSettle();

      expect(find.text('25'), findsOneWidget);
      for (var i = 0; i < 25; i++) {
        expect(find.text('Jogador $i'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  });
}

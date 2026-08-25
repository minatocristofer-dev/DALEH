import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/home/inicio_screen.dart';
import 'package:daleh_app/features/matches/matches_providers.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/notifications/models/app_notification.dart';
import 'package:daleh_app/features/notifications/notifications_providers.dart';
import 'package:daleh_app/features/teams/minhas_convocacoes_screen.dart';
import 'package:daleh_app/features/teams/models/call_up.dart';
import 'package:daleh_app/features/teams/teams_providers.dart';

Match _partida({required String id, required DateTime scheduledAt, String status = 'scheduled'}) {
  return Match.fromJson({
    'id': id,
    'createdById': 'user-criador',
    'modalidadeId': 'mod-1',
    'modalidade': {'id': 'mod-1', 'key': 'SOCIETY', 'label': 'Society'},
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status,
    'visibility': 'public',
  });
}

CallUp _convocacao(String status) {
  return CallUp.fromJson({
    'id': 'callup-$status',
    'teamId': 'time-1',
    'matchId': null,
    'userId': 'user-1',
    'venueNameSnapshot': 'Arena Teste',
    'scheduledDate': '2026-09-10T00:00:00.000Z',
    'scheduledTime': '20:00',
    'status': status,
    'respondedAt': null,
    'createdAt': '2026-08-21T00:00:00.000Z',
    'team': {'id': 'time-1', 'name': 'DALEH FC', 'crestUrl': null},
  });
}

Widget _app({
  List<Match> partidas = const [],
  List<CallUp> convocacoes = const [],
  List<AppNotification> notificacoes = const [],
  void Function(int aba)? onNavegar,
}) {
  return ProviderScope(
    overrides: [
      minhasPartidasProvider.overrideWith((ref) => Future.value(partidas)),
      minhasConvocacoesProvider.overrideWith((ref) => Future.value(convocacoes)),
      notificationsProvider.overrideWith((ref) => Future.value(notificacoes)),
    ],
    child: MaterialApp(home: Scaffold(body: InicioScreen(onNavegarParaAba: onNavegar ?? (_) {}))),
  );
}

void main() {
  testWidgets('mostra o próximo jogo real (futuro, não encerrado) quando existe', (tester) async {
    await tester.pumpWidget(_app(partidas: [
      _partida(id: 'passado', scheduledAt: DateTime.now().subtract(const Duration(days: 1))),
      _partida(id: 'futuro', scheduledAt: DateTime.now().add(const Duration(days: 2))),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Society'), findsOneWidget);
  });

  testWidgets('sem jogo futuro, mostra aviso honesto em vez de inventar um jogo', (tester) async {
    await tester.pumpWidget(_app(partidas: [
      _partida(id: 'passado', scheduledAt: DateTime.now().subtract(const Duration(days: 1))),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum jogo agendado. Bora marcar um?'), findsOneWidget);
  });

  testWidgets('badge de convocações pendentes reflete a contagem real e abre Minhas Convocações ao tocar', (tester) async {
    await tester.pumpWidget(_app(convocacoes: [_convocacao('PENDENTE'), _convocacao('CONFIRMADO')]));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets); // só 1 das 2 é PENDENTE

    await tester.tap(find.text('Convocações'));
    await tester.pumpAndSettle();

    expect(find.byType(MinhasConvocacoesScreen), findsOneWidget);
  });

  testWidgets('sem convocação pendente, não mostra nenhum badge', (tester) async {
    await tester.pumpWidget(_app(convocacoes: [_convocacao('CONFIRMADO')]));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
  });

  testWidgets('acesso rápido navega pra abas do bottom nav via callback, sem empilhar telas novas', (tester) async {
    final abasNavegadas = <int>[];
    await tester.pumpWidget(_app(onNavegar: abasNavegadas.add));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meus Jogos'));
    await tester.tap(find.text('Times'));
    await tester.tap(find.text('Quadras'));

    expect(abasNavegadas, [2, 1, 3]);
  });

  testWidgets('atividade recente mostra notificações reais, mais recentes primeiro na lista devolvida pela API', (tester) async {
    await tester.pumpWidget(_app(notificacoes: [
      AppNotification.fromJson({
        'id': 'n1',
        'type': 'team_member_added',
        'payload': {'titulo': 'Você entrou no time', 'corpo': 'Bem-vindo à DALEH FC.', 'teamId': 'time-1'},
        'readAt': null,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      }),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Você entrou no time'), findsOneWidget);
  });

  testWidgets('sem nenhuma notificação, mostra aviso honesto em vez de lista vazia sem explicação', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma atividade ainda.'), findsOneWidget);
  });
}

import 'package:daleh_app/features/matches/minha_reserva_screen.dart';
import 'package:daleh_app/features/matches/matches_providers.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/teams/teams_providers.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _presenca(String userId, String nome, {String? pagoEm}) => {
      'id': 'att-$userId',
      'matchId': 'm1',
      'userId': userId,
      'status': 'confirmed',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'pagoEm': pagoEm,
      'valorDevido': 20,
      'user': {'id': userId, 'fullName': nome, 'avatarUrl': null},
    };

Match _partida({bool covered = true, double? valor = 120}) => Match.fromJson({
      'id': 'm1',
      'createdById': 'criador',
      'modalidadeId': 'mod-society',
      'modalidade': {'label': 'Futebol Society'},
      'venue': {'name': 'Arena Sports', 'address': 'Santa Maria / RS', 'covered': covered},
      'scheduledAt': '2026-09-28T22:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
      'souGestorDaSumula': false,
      'valorQuadra': valor,
      'resumoPagamento': {
        'totalEsperado': valor,
        'totalRecebido': 20,
        'confirmados': 2,
        'pagos': 1,
        'porTime': null,
        'valorPorJogadorAvulsa': valor == null ? null : 60,
      },
      'attendance': [
        _presenca('eu', 'Cristofer', pagoEm: '2026-09-27T12:00:00.000Z'),
        _presenca('outro', 'Gabriel'),
      ],
      'events': [],
    });

Widget _tela(Match partida, {String? euId = 'eu'}) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        partidaDetalheProvider('m1').overrideWith((ref) async => partida),
        meuUserIdProvider.overrideWith((ref) => euId),
      ],
      child: MaterialApp(
        theme: buildDalehTheme(),
        home: const MinhaReservaScreen(matchId: 'm1'),
      ),
    );

void main() {
  testWidgets('mostra quadra, status, data/horário, quadra coberta e valor por jogador', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_tela(_partida()));
    await tester.pumpAndSettle();

    expect(find.text('Arena Sports'), findsOneWidget);
    expect(find.text('RESERVA CONFIRMADA'), findsOneWidget);
    expect(find.text('QUADRA COBERTA'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
    expect(find.text('R\$ 120,00'), findsOneWidget);
    expect(find.text('R\$ 60,00 por jogador'), findsOneWidget);
    expect(find.text('Controle de pagamento'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('COMPARTILHAR RESERVA'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('COMPARTILHAR RESERVA'), findsOneWidget);
  });

  testWidgets('sem valor informado mostra "Não informado" sem inventar número', (tester) async {
    await tester.pumpWidget(_tela(_partida(valor: null)));
    await tester.pumpAndSettle();

    expect(find.text('Não informado'), findsOneWidget);
    expect(find.text('Aguardando o organizador'), findsOneWidget);
    expect(find.textContaining('por jogador'), findsNothing);
  });

  testWidgets('quadra sem informação de cobertura não mostra "Sim" nem "Não" por engano', (tester) async {
    final semInfo = Match.fromJson({
      'id': 'm1',
      'createdById': 'criador',
      'modalidadeId': 'x',
      'scheduledAt': '2026-09-28T22:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
      'attendance': [],
      'events': [],
    });
    await tester.pumpWidget(_tela(semInfo));
    await tester.pumpAndSettle();

    expect(find.text('Não informado'), findsNWidgets(2));
    expect(find.text('Sim'), findsNothing);
  });

  testWidgets('botão de cancelar presença só aparece pra quem está confirmado', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(_tela(_partida(), euId: 'eu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CANCELAR PRESENÇA'), 300, scrollable: find.byType(Scrollable).first);
    await tester.scrollUntilVisible(find.text('CANCELAR PRESENÇA'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('CANCELAR PRESENÇA'), findsOneWidget);

    await tester.pumpWidget(_tela(_partida(), euId: 'estranho'));
    await tester.pumpAndSettle();
    expect(find.text('CANCELAR PRESENÇA'), findsNothing);
  });
}

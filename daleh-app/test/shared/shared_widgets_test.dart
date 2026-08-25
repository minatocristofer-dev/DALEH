import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/teams/models/call_up.dart';
import 'package:daleh_app/features/teams/models/team.dart';
import 'package:daleh_app/shared/widgets/call_up_card.dart';
import 'package:daleh_app/shared/widgets/empty_state.dart';
import 'package:daleh_app/shared/widgets/error_state.dart';
import 'package:daleh_app/shared/widgets/team_card.dart';
import 'package:daleh_app/theme/daleh_theme.dart';

Widget _comTema(Widget filho) => MaterialApp(theme: buildDalehTheme(), home: Scaffold(body: filho));

void main() {
  group('EmptyState', () {
    testWidgets('estado vazio de Meus Times mostra título, subtítulo e CTA', (tester) async {
      var tocou = false;
      await tester.pumpWidget(_comTema(EmptyState(
        icon: Icons.shield_outlined,
        titulo: 'Você ainda não tem um time.',
        subtitulo: 'Crie seu time, monte seu elenco e comece a construir sua história.',
        ctaLabel: 'CRIAR MEU TIME',
        onCta: () => tocou = true,
      )));

      expect(find.text('Você ainda não tem um time.'), findsOneWidget);
      expect(find.text('CRIAR MEU TIME'), findsOneWidget);

      await tester.tap(find.text('CRIAR MEU TIME'));
      expect(tocou, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('erro 403 mostra mensagem de permissão', (tester) async {
      await tester.pumpWidget(_comTema(ErrorState(
        erro: ApiException('sem permissão bruta', kind: ApiErrorKind.forbidden),
      )));

      expect(find.text('Você não tem permissão pra ver ou fazer isso.'), findsOneWidget);
    });

    testWidgets('erro de rede mostra botão de tentar de novo e aciona callback', (tester) async {
      var tentou = false;
      await tester.pumpWidget(_comTema(ErrorState(
        erro: ApiException('Sem conexão com a internet.', kind: ApiErrorKind.network),
        onTentarNovamente: () => tentou = true,
      )));

      expect(find.text('Sem conexão com a internet.'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      expect(tentou, isTrue);
    });
  });

  group('TeamCard', () {
    testWidgets('mostra nome, localização, papel e quantidade de jogadores', (tester) async {
      var tocou = false;
      final time = Team.fromJson({
        'id': 't1',
        'name': 'DALEH FC',
        'crestUrl': null,
        'city': 'Santa Maria',
        'state': 'RS',
        'ownerId': 'user-1',
        'meuPapel': 'CAPITAO',
        'totalMembros': 12,
      });

      await tester.pumpWidget(_comTema(TeamCard(time: time, souDono: false, onTap: () => tocou = true)));

      expect(find.text('DALEH FC'), findsOneWidget);
      expect(find.text('Santa Maria / RS'), findsOneWidget);
      expect(find.text('12 jogadores'), findsOneWidget);
      expect(find.text('CAPITÃO'), findsOneWidget);

      await tester.tap(find.byType(TeamCard));
      expect(tocou, isTrue);
    });
  });

  group('CallUpCard', () {
    CallUp callUpPendente() => CallUp.fromJson({
          'id': 'c1',
          'teamId': 't1',
          'matchId': null,
          'userId': 'u1',
          'venueNameSnapshot': 'Arena Teste',
          'scheduledDate': '2026-09-10T00:00:00.000Z',
          'scheduledTime': '20:00',
          'status': 'PENDENTE',
          'respondedAt': null,
          'createdAt': '2026-08-21T00:00:00.000Z',
          'team': {'id': 't1', 'name': 'DALEH FC', 'crestUrl': null},
        });

    testWidgets('convocação pendente mostra botões Confirmar e Recusar', (tester) async {
      var confirmou = false;
      var recusou = false;

      await tester.pumpWidget(_comTema(CallUpCard(
        callUp: callUpPendente(),
        onConfirmar: () => confirmou = true,
        onRecusar: () => recusou = true,
      )));

      expect(find.text('Arena Teste'), findsOneWidget);
      expect(find.text('PENDENTE'), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      expect(confirmou, isTrue);

      await tester.tap(find.text('Recusar'));
      expect(recusou, isTrue);
    });

    testWidgets('convocação já confirmada não mostra botões de ação', (tester) async {
      final confirmada = CallUp.fromJson({
        'id': 'c2',
        'teamId': 't1',
        'matchId': null,
        'userId': 'u1',
        'venueNameSnapshot': 'Arena Teste',
        'scheduledDate': '2026-09-10T00:00:00.000Z',
        'scheduledTime': '20:00',
        'status': 'CONFIRMADO',
        'respondedAt': '2026-08-21T01:00:00.000Z',
        'createdAt': '2026-08-21T00:00:00.000Z',
      });

      await tester.pumpWidget(_comTema(CallUpCard(callUp: confirmada, onConfirmar: () {}, onRecusar: () {})));

      expect(find.text('Confirmar'), findsNothing);
      expect(find.text('Recusar'), findsNothing);
      expect(find.text('CONFIRMADO'), findsOneWidget);
    });
  });
}

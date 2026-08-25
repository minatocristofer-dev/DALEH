import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/notifications/models/app_notification.dart';
import 'package:daleh_app/features/notifications/notifications_providers.dart';
import 'package:daleh_app/features/notifications/notifications_screen.dart';
import 'package:daleh_app/features/teams/team_detail_screen.dart';
import 'package:daleh_app/features/venues/minhas_reservas_screen.dart';

class _FakeNotificationsActions extends NotificationsActions {
  final List<String> marcadas = [];
  _FakeNotificationsActions(super.ref);

  @override
  Future<void> marcarLida(String id) async {
    marcadas.add(id);
  }
}

AppNotification _notificacao({
  required String id,
  required String type,
  required Map<String, dynamic> payload,
  bool lida = false,
}) {
  return AppNotification(
    id: id,
    type: type,
    titulo: 'Título $id',
    corpo: 'Corpo $id',
    createdAt: DateTime(2026, 8, 20),
    readAt: lida ? DateTime(2026, 8, 21) : null,
    payload: payload,
  );
}

Future<_FakeNotificationsActions> _montar(
  WidgetTester tester, {
  required List<AppNotification> notificacoes,
}) async {
  // NotificationsScreen só lê notificationsActionsProvider dentro do onTap
  // (ainda não disparado ao montar a tela) — um Provider comum do Riverpod é
  // preguiçoso, então, se a gente esperasse capturar o fake via a própria
  // árvore de widgets, ele nunca seria construído a tempo do teste ler
  // `fake` depois do pump. Por isso o container é criado à parte e o
  // provider é forçado a existir com `container.read` antes de montar a UI.
  final container = ProviderContainer(
    overrides: [
      notificationsProvider.overrideWith((ref) => Future.value(notificacoes)),
      notificationsActionsProvider.overrideWith((ref) => _FakeNotificationsActions(ref)),
    ],
  );
  addTearDown(container.dispose);
  final fake = container.read(notificationsActionsProvider) as _FakeNotificationsActions;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('notificação não lida com destino navegável: marca como lida e navega', (tester) async {
    final fake = await _montar(tester, notificacoes: [
      _notificacao(id: 'n1', type: 'team_member_added', payload: {'teamId': 'time-1'}),
    ]);

    await tester.tap(find.text('Título n1'));
    await tester.pumpAndSettle();

    expect(fake.marcadas, ['n1']);
    expect(find.byType(TeamDetailScreen), findsOneWidget);
  });

  testWidgets('notificação já lida: não chama marcarLida de novo, mas ainda navega', (tester) async {
    final fake = await _montar(tester, notificacoes: [
      _notificacao(id: 'n2', type: 'booking_confirmed', payload: {'bookingId': 'b1'}, lida: true),
    ]);

    await tester.tap(find.text('Título n2'));
    await tester.pumpAndSettle();

    expect(fake.marcadas, isEmpty, reason: 'já estava lida — não deve chamar a API de novo');
    expect(find.byType(MinhasReservasScreen), findsOneWidget);
  });

  testWidgets('payload sem o campo necessário: marca como lida e não navega, sem crashar', (tester) async {
    final fake = await _montar(tester, notificacoes: [
      _notificacao(id: 'n3', type: 'team_member_added', payload: <String, dynamic>{}),
    ]);

    await tester.tap(find.text('Título n3'));
    await tester.pumpAndSettle();

    expect(fake.marcadas, ['n3']);
    expect(find.byType(NotificationsScreen), findsOneWidget, reason: 'continua na própria tela, sem navegar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tipo desconhecido: marca como lida e não navega, sem crashar', (tester) async {
    final fake = await _montar(tester, notificacoes: [
      _notificacao(id: 'n4', type: 'tipo_futuro_desconhecido', payload: {'algo': 'x'}),
    ]);

    await tester.tap(find.text('Título n4'));
    await tester.pumpAndSettle();

    expect(fake.marcadas, ['n4']);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/venues/minha_quadra_detail_screen.dart';
import 'package:daleh_app/features/venues/models/venue.dart';
import 'package:daleh_app/features/venues/models/venue_blocked_date.dart';
import 'package:daleh_app/features/venues/models/venue_dashboard.dart';
import 'package:daleh_app/features/venues/models/venue_slot.dart';
import 'package:daleh_app/features/venues/venues_providers.dart';

// QA Round 3, item 16 — testes novos obrigatórios: dashboard locador,
// horário fixo, remover horário fixo, autorização de horário fixo (lado
// backend já coberto em venues.service.spec.ts; aqui cobre a UI).
class _FakeVenuesActions extends VenuesActions {
  final List<(String bookingId, bool isFixed, String? nome)> chamadas = [];
  _FakeVenuesActions(super.ref);

  @override
  Future<void> marcarComoFixo(
    String venueId,
    String bookingId, {
    required bool isFixed,
    String? fixedTeamName,
    required String dataAgenda,
  }) async {
    chamadas.add((bookingId, isFixed, fixedTeamName));
  }
}

Venue _quadra() => Venue(
      id: 'v1',
      ownerId: 'owner-1',
      name: 'Arena Teste',
      covered: true,
      hasParking: true,
      hasBar: false,
      hasLockerRoom: false,
      rentsVests: false,
      rentsBalls: false,
      avgRating: 0,
      slots: const [],
    );

VenueDashboard _dashboardVazio() => VenueDashboard(
      horariosDisponiveisHoje: 0,
      reservasHoje: 0,
      reservasMes: 0,
      valorEmReservasHoje: 0,
      valorEmReservasMes: 0,
      indiceOcupacaoMes: 0,
    );

VenueSlot _slot({
  required String id,
  required String startTime,
  bool ocupado = false,
  bool fixo = false,
  String? fixedTeamName,
  String? bookingId,
  String? reservadoPorNome,
}) =>
    VenueSlot(
      id: id,
      venueId: 'v1',
      weekday: DateTime.now().weekday % 7,
      startTime: startTime,
      endTime: startTime,
      price: 100,
      isRecurring: true,
      ocupado: ocupado,
      fixo: fixo,
      fixedTeamName: fixedTeamName,
      bookingId: bookingId,
      reservadoPorNome: reservadoPorNome,
    );

Future<_FakeVenuesActions> _montar(WidgetTester tester, {required List<VenueSlot> slots}) async {
  final container = ProviderContainer(
    overrides: [
      quadraDetalheProvider.overrideWith((ref, id) => Future.value(_quadra())),
      venueDashboardProvider.overrideWith((ref, id) => Future.value(_dashboardVazio())),
      disponibilidadeProvider.overrideWith((ref, query) => Future.value(slots)),
      bloqueiosDaQuadraProvider.overrideWith((ref, id) => Future.value(const <VenueBlockedDate>[])),
      reservasDaQuadraProvider.overrideWith((ref, id) => Future.value(const [])),
      venuesActionsProvider.overrideWith((ref) => _FakeVenuesActions(ref)),
    ],
  );
  addTearDown(container.dispose);
  final fake = container.read(venuesActionsProvider) as _FakeVenuesActions;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MinhaQuadraDetailScreen(venueId: 'v1')),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('painel do locador mostra agenda com os estados LIVRE, RESERVADO e FIXO', (tester) async {
    await _montar(tester, slots: [
      _slot(id: 's1', startTime: '18:00'),
      _slot(id: 's2', startTime: '19:00', ocupado: true, bookingId: 'b2', reservadoPorNome: 'João'),
      _slot(id: 's3', startTime: '20:00', ocupado: true, fixo: true, bookingId: 'b3', fixedTeamName: 'Fut das 20'),
    ]);

    expect(find.text('LIVRE'), findsOneWidget);
    expect(find.text('RESERVADO'), findsOneWidget);
    expect(find.text('FIXO'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Fut das 20'), findsOneWidget);
  });

  testWidgets('marcar horário reservado como fixo chama a ação com isFixed true', (tester) async {
    final fake = await _montar(tester, slots: [
      _slot(id: 's2', startTime: '19:00', ocupado: true, bookingId: 'b2', reservadoPorNome: 'João'),
    ]);

    await tester.tap(find.byTooltip('Marcar como horário fixo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fut da Firma');
    await tester.tap(find.text('Marcar como fixo'));
    await tester.pumpAndSettle();

    expect(fake.chamadas, [('b2', true, 'Fut da Firma')]);
  });

  testWidgets('remover horário fixo chama a ação com isFixed false', (tester) async {
    final fake = await _montar(tester, slots: [
      _slot(id: 's3', startTime: '20:00', ocupado: true, fixo: true, bookingId: 'b3', fixedTeamName: 'Fut das 20'),
    ]);

    await tester.tap(find.byTooltip('Remover horário fixo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(fake.chamadas, [('b3', false, null)]);
  });

  testWidgets('horário livre não mostra ação de marcar/remover fixo (não existe reserva pra fixar)', (tester) async {
    await _montar(tester, slots: [_slot(id: 's1', startTime: '18:00')]);

    expect(find.byTooltip('Marcar como horário fixo'), findsNothing);
    expect(find.byTooltip('Remover horário fixo'), findsNothing);
  });
}

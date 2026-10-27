import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/venues/minha_quadra_detail_screen.dart';
import 'package:daleh_app/features/venues/models/booking.dart';

// QA Round 3, item 16 — "share view renderiza" pro card de Compartilhar
// Confronto da Quadra (item 5). Usa só dado real da própria reserva, sem
// inventar um segundo time (ver comentário em ConfrontoQuadraShareCard).
Booking _reserva({required DateTime data, bool isFixed = false, String? fixedTeamName, String? bookedByUserFullName}) => Booking(
      id: 'b1',
      venueSlotId: 's1',
      bookedById: 'u1',
      date: data,
      status: 'confirmed',
      venueSlotStartTime: '19:00',
      venueSlotEndTime: '20:00',
      bookedByUserFullName: bookedByUserFullName,
      isFixed: isFixed,
      fixedTeamName: fixedTeamName,
    );

void main() {
  testWidgets('reserva normal mostra quem reservou, quadra, data e horário', (tester) async {
    final reserva = _reserva(data: DateTime(2026, 11, 2), bookedByUserFullName: 'João');

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ConfrontoQuadraShareCard(reserva: reserva, venueName: 'Arena Teste'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('João'), findsOneWidget);
    expect(find.text('Arena Teste'), findsOneWidget);
    expect(find.textContaining('02/11/2026'), findsWidgets);
    expect(find.textContaining('19:00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserva fixa mostra o nome do time/grupo e "HOJE ÀS" quando a data é hoje', (tester) async {
    final reserva = _reserva(data: DateTime.now(), isFixed: true, fixedTeamName: 'Fut das 20');

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ConfrontoQuadraShareCard(reserva: reserva, venueName: 'Arena Teste'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fut das 20'), findsOneWidget);
    expect(find.textContaining('HOJE ÀS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

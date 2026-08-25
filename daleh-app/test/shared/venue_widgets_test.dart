import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/venues/models/booking.dart';
import 'package:daleh_app/features/venues/models/venue.dart';
import 'package:daleh_app/features/venues/models/venue_slot.dart';
import 'package:daleh_app/shared/widgets/booking_card.dart';
import 'package:daleh_app/shared/widgets/error_state.dart';
import 'package:daleh_app/shared/widgets/venue_card.dart';
import 'package:daleh_app/shared/widgets/venue_slot_tile.dart';
import 'package:daleh_app/theme/daleh_theme.dart';

Widget _comTema(Widget filho) => MaterialApp(theme: buildDalehTheme(), home: Scaffold(body: filho));

void main() {
  group('VenueCard', () {
    testWidgets('mostra nome, endereço e atributos reais da quadra', (tester) async {
      var tocou = false;
      final quadra = Venue.fromJson({
        'id': 'v1',
        'ownerId': 'user-1',
        'name': 'Arena Society',
        'address': 'Rua Teste, 123',
        'covered': true,
        'hasParking': true,
        'hasBar': false,
        'hasLockerRoom': false,
        'rentsVests': false,
        'rentsBalls': false,
        'pricePerHour': 120.0,
        'avgRating': 0,
      });

      await tester.pumpWidget(_comTema(VenueCard(quadra: quadra, onTap: () => tocou = true)));

      expect(find.text('Arena Society'), findsOneWidget);
      expect(find.text('Rua Teste, 123'), findsOneWidget);
      expect(find.text('Coberta'), findsOneWidget);
      expect(find.text('Estacionamento'), findsOneWidget);
      expect(find.text('R\$120/h'), findsOneWidget);

      await tester.tap(find.byType(VenueCard));
      expect(tocou, isTrue);
    });

    testWidgets('não mostra avaliação quando avgRating é 0 (nunca avaliada de verdade)', (tester) async {
      final quadra = Venue.fromJson({
        'id': 'v1',
        'ownerId': 'user-1',
        'name': 'Arena Society',
        'covered': false,
        'hasParking': false,
        'hasBar': false,
        'hasLockerRoom': false,
        'rentsVests': false,
        'rentsBalls': false,
        'avgRating': 0,
      });

      await tester.pumpWidget(_comTema(VenueCard(quadra: quadra, onTap: () {})));

      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('VenueSlotTile', () {
    testWidgets('slot disponível mostra chip DISPONÍVEL e aciona onTap', (tester) async {
      var tocou = false;
      final slot = VenueSlot.fromJson({
        'id': 's1',
        'venueId': 'v1',
        'weekday': 0,
        'startTime': '18:00',
        'endTime': '19:00',
        'price': 100.0,
        'isRecurring': true,
        'ocupado': false,
      });

      await tester.pumpWidget(_comTema(VenueSlotTile(slot: slot, onTap: () => tocou = true)));

      expect(find.text('DISPONÍVEL'), findsOneWidget);
      await tester.tap(find.byType(VenueSlotTile));
      expect(tocou, isTrue);
    });

    testWidgets('slot ocupado mostra chip OCUPADO e ignora toques', (tester) async {
      var tocou = false;
      final slot = VenueSlot.fromJson({
        'id': 's2',
        'venueId': 'v1',
        'weekday': 0,
        'startTime': '19:00',
        'endTime': '20:00',
        'price': 100.0,
        'isRecurring': true,
        'ocupado': true,
      });

      await tester.pumpWidget(_comTema(VenueSlotTile(slot: slot, onTap: () => tocou = true)));

      expect(find.text('OCUPADO'), findsOneWidget);
      await tester.tap(find.byType(VenueSlotTile));
      expect(tocou, isFalse);
    });
  });

  group('BookingCard', () {
    testWidgets('mostra quadra, data, horário e botão de cancelar quando não cancelada', (tester) async {
      var cancelou = false;
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-1',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'pending',
        'venueSlot': {
          'id': 's1',
          'venueId': 'v1',
          'weekday': 1,
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 100.0,
          'isRecurring': true,
          'venue': {'id': 'v1', 'name': 'Arena Society', 'address': null},
        },
      });

      await tester.pumpWidget(_comTema(BookingCard(reserva: reserva, onCancelar: () => cancelou = true)));

      expect(find.text('Arena Society'), findsOneWidget);
      expect(find.text('PENDENTE'), findsOneWidget);
      expect(find.text('Cancelar reserva'), findsOneWidget);

      await tester.tap(find.text('Cancelar reserva'));
      expect(cancelou, isTrue);
    });

    testWidgets('reserva cancelada não mostra botão de cancelar', (tester) async {
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-1',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'cancelled',
      });

      await tester.pumpWidget(_comTema(BookingCard(reserva: reserva, onCancelar: () {})));

      expect(find.text('CANCELADA'), findsOneWidget);
      expect(find.text('Cancelar reserva'), findsNothing);
    });
  });

  group('ErrorState — conflito 409', () {
    testWidgets('mostra a mensagem real do backend pra um horário já reservado', (tester) async {
      await tester.pumpWidget(_comTema(ErrorState(
        erro: ApiException('Esse horário já está reservado nessa data.', kind: ApiErrorKind.conflict),
      )));

      expect(find.text('Esse horário já está reservado nessa data.'), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/venues/models/booking.dart';
import 'package:daleh_app/features/venues/models/venue.dart';
import 'package:daleh_app/features/venues/models/venue_slot.dart';

void main() {
  group('Venue.fromJson', () {
    test('lê o formato de GET /venues (listagem, sem slots)', () {
      final quadra = Venue.fromJson({
        'id': 'v1',
        'ownerId': 'user-1',
        'name': 'Arena Society',
        'address': 'Rua Teste, 123',
        'covered': true,
        'hasParking': true,
        'hasBar': false,
        'hasLockerRoom': true,
        'rentsVests': false,
        'rentsBalls': true,
        'pricePerHour': 120.0,
        'avgRating': 0,
      });

      expect(quadra.name, 'Arena Society');
      expect(quadra.covered, isTrue);
      expect(quadra.hasBar, isFalse);
      expect(quadra.slots, isNull);
      expect(quadra.temAvaliacao, isFalse, reason: 'avgRating 0 nunca foi recalculado — não é uma avaliação real');
      expect(quadra.souDono('user-1'), isTrue);
    });

    test('lê o formato de GET /venues/:id (detalhe, com slots)', () {
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
        'avgRating': 4.5,
        'slots': [
          {
            'id': 'slot-1',
            'venueId': 'v1',
            'weekday': 0,
            'startTime': '18:00',
            'endTime': '19:00',
            'price': 100.0,
            'isRecurring': true,
          },
        ],
      });

      expect(quadra.slots, hasLength(1));
      expect(quadra.slots!.first.startTime, '18:00');
      expect(quadra.temAvaliacao, isTrue);
    });
  });

  group('VenueSlot.fromJson', () {
    test('lê ocupado só quando vem de /availability', () {
      final disponivel = VenueSlot.fromJson({
        'id': 's1',
        'venueId': 'v1',
        'weekday': 2,
        'startTime': '20:00',
        'endTime': '21:00',
        'price': 90.0,
        'isRecurring': true,
        'ocupado': false,
      });
      final doDetalhe = VenueSlot.fromJson({
        'id': 's2',
        'venueId': 'v1',
        'weekday': 2,
        'startTime': '21:00',
        'endTime': '22:00',
        'price': 90.0,
        'isRecurring': true,
      });

      expect(disponivel.ocupado, isFalse);
      expect(doDetalhe.ocupado, isNull);
    });
  });

  group('Booking.fromJson', () {
    test('lê o retorno cru de POST .../bookings (sem venueSlot aninhado)', () {
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-1',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'pending',
      });

      expect(reserva.pendente, isTrue);
      expect(reserva.venueName, isNull);
    });

    test('lê o formato de GET /bookings/mine (com venueSlot.venue aninhado)', () {
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-1',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'confirmed',
        'venueSlot': {
          'id': 's1',
          'venueId': 'v1',
          'weekday': 1,
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 100.0,
          'isRecurring': true,
          'venue': {'id': 'v1', 'name': 'Arena Society', 'address': 'Rua Teste, 123'},
        },
      });

      expect(reserva.confirmada, isTrue);
      expect(reserva.venueName, 'Arena Society');
      expect(reserva.venueSlotStartTime, '19:00');
    });

    test('lê o formato de GET /venues/:id/bookings (com bookedByUser resolvido)', () {
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
        'bookedByUser': {'id': 'user-1', 'fullName': 'Jogador Teste', 'avatarUrl': null},
      });

      expect(reserva.bookedByUserFullName, 'Jogador Teste');
    });

    test('bookedByUser fica nulo quando o endpoint não devolve esse campo', () {
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-1',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'pending',
      });

      expect(reserva.bookedByUserFullName, isNull);
    });
  });
}

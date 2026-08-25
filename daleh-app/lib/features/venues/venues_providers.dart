import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'models/booking.dart';
import 'models/venue.dart';
import 'models/venue_slot.dart';
import 'venues_repository.dart';

final venuesRepositoryProvider = Provider((ref) => VenuesRepository(ref.read(apiClientProvider)));

/// Texto de busca por cidade/endereço da tela "Explorar Quadras" — puro
/// estado de UI, não vem de sessão nenhuma.
final filtroQuadrasProvider = StateProvider.autoDispose<String>((ref) => '');

final quadrasPublicasProvider = FutureProvider.autoDispose<List<Venue>>((ref) {
  final filtro = ref.watch(filtroQuadrasProvider);
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.listarQuadras(token, city: filtro.isEmpty ? null : filtro));
});

final minhasQuadrasProvider = FutureProvider.autoDispose<List<Venue>>((ref) {
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.minhasQuadras(token));
});

final quadraDetalheProvider = FutureProvider.autoDispose.family<Venue, String>((ref, venueId) {
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.obterQuadra(venueId, token));
});

typedef DisponibilidadeQuery = ({String venueId, String data});

final disponibilidadeProvider =
    FutureProvider.autoDispose.family<List<VenueSlot>, DisponibilidadeQuery>((ref, query) {
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.disponibilidade(query.venueId, query.data, token));
});

final minhasReservasProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.minhasReservas(token));
});

final reservasDaQuadraProvider = FutureProvider.autoDispose.family<List<Booking>, String>((ref, venueId) {
  final repo = ref.read(venuesRepositoryProvider);
  return comSessao(ref, (token) => repo.reservasDaQuadra(venueId, token));
});

/// Ações que alteram estado no backend. Depois de cada uma, invalidam os
/// providers de leitura afetados (mesmo padrão de Times/Jogos).
class VenuesActions {
  final Ref ref;
  VenuesActions(this.ref);

  VenuesRepository get _repo => ref.read(venuesRepositoryProvider);

  Future<Venue> criarQuadra({
    required String name,
    String? address,
    bool? covered,
    bool? hasParking,
    bool? hasBar,
    bool? hasLockerRoom,
    bool? rentsVests,
    bool? rentsBalls,
    double? pricePerHour,
  }) async {
    final quadra = await comSessao(
      ref,
      (token) => _repo.criarQuadra(
        token,
        name: name,
        address: address,
        covered: covered,
        hasParking: hasParking,
        hasBar: hasBar,
        hasLockerRoom: hasLockerRoom,
        rentsVests: rentsVests,
        rentsBalls: rentsBalls,
        pricePerHour: pricePerHour,
      ),
    );
    ref.invalidate(minhasQuadrasProvider);
    return quadra;
  }

  Future<void> editarQuadra(
    String venueId, {
    String? name,
    String? address,
    bool? covered,
    bool? hasParking,
    bool? hasBar,
    bool? hasLockerRoom,
    bool? rentsVests,
    bool? rentsBalls,
    double? pricePerHour,
  }) async {
    await comSessao(
      ref,
      (token) => _repo.editarQuadra(
        venueId,
        token,
        name: name,
        address: address,
        covered: covered,
        hasParking: hasParking,
        hasBar: hasBar,
        hasLockerRoom: hasLockerRoom,
        rentsVests: rentsVests,
        rentsBalls: rentsBalls,
        pricePerHour: pricePerHour,
      ),
    );
    ref.invalidate(quadraDetalheProvider(venueId));
    ref.invalidate(minhasQuadrasProvider);
  }

  Future<void> criarSlot(
    String venueId, {
    required int weekday,
    required String startTime,
    required String endTime,
    required double price,
  }) async {
    await comSessao(
      ref,
      (token) => _repo.criarSlot(venueId, token, weekday: weekday, startTime: startTime, endTime: endTime, price: price),
    );
    ref.invalidate(quadraDetalheProvider(venueId));
  }

  Future<void> removerSlot(String venueId, String slotId) async {
    await comSessao(ref, (token) => _repo.removerSlot(venueId, slotId, token));
    ref.invalidate(quadraDetalheProvider(venueId));
  }

  Future<Booking> reservar(String venueId, String slotId, {required String data}) async {
    final reserva = await comSessao(ref, (token) => _repo.reservar(venueId, slotId, token, data: data));
    ref.invalidate(disponibilidadeProvider((venueId: venueId, data: data)));
    ref.invalidate(minhasReservasProvider);
    return reserva;
  }

  Future<void> cancelarReserva(String bookingId) async {
    await comSessao(ref, (token) => _repo.cancelarReserva(bookingId, token));
    ref.invalidate(minhasReservasProvider);
  }

  Future<void> confirmarReserva(String venueId, String bookingId) async {
    await comSessao(ref, (token) => _repo.atualizarStatusReserva(bookingId, token, status: 'confirmed'));
    ref.invalidate(reservasDaQuadraProvider(venueId));
  }

  Future<void> recusarReserva(String venueId, String bookingId) async {
    await comSessao(ref, (token) => _repo.atualizarStatusReserva(bookingId, token, status: 'cancelled'));
    ref.invalidate(reservasDaQuadraProvider(venueId));
  }
}

final venuesActionsProvider = Provider((ref) => VenuesActions(ref));

import '../../core/api_client.dart';
import 'models/booking.dart';
import 'models/venue.dart';
import 'models/venue_slot.dart';

/// Só chama endpoints que já existem em `src/modules/venues` — nenhum
/// endpoint foi inventado.
class VenuesRepository {
  final ApiClient _api;
  VenuesRepository(this._api);

  Future<Venue> criarQuadra(
    String token, {
    required String name,
    String? address,
    double? lat,
    double? lng,
    bool? covered,
    bool? hasParking,
    bool? hasBar,
    bool? hasLockerRoom,
    bool? rentsVests,
    bool? rentsBalls,
    double? pricePerHour,
  }) async {
    final resp = await _api.postAutenticado(
      '/venues',
      token: token,
      corpo: {
        'name': name,
        if (address != null && address.isNotEmpty) 'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (covered != null) 'covered': covered,
        if (hasParking != null) 'hasParking': hasParking,
        if (hasBar != null) 'hasBar': hasBar,
        if (hasLockerRoom != null) 'hasLockerRoom': hasLockerRoom,
        if (rentsVests != null) 'rentsVests': rentsVests,
        if (rentsBalls != null) 'rentsBalls': rentsBalls,
        if (pricePerHour != null) 'pricePerHour': pricePerHour,
      },
    );
    return Venue.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<Venue>> listarQuadras(String token, {String? city}) async {
    final sufixo = (city != null && city.isNotEmpty) ? '?${Uri(queryParameters: {'city': city}).query}' : '';
    final lista = await _api.getLista('/venues$sufixo', token: token);
    return lista.map((v) => Venue.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<List<Venue>> minhasQuadras(String token) async {
    final lista = await _api.getLista('/venues/mine', token: token);
    return lista.map((v) => Venue.fromJson(v as Map<String, dynamic>)).toList();
  }

  Future<Venue> obterQuadra(String venueId, String token) async {
    final resp = await _api.getMapa('/venues/$venueId', token: token);
    return Venue.fromJson(resp);
  }

  Future<Venue> editarQuadra(
    String venueId,
    String token, {
    String? name,
    String? address,
    double? lat,
    double? lng,
    bool? covered,
    bool? hasParking,
    bool? hasBar,
    bool? hasLockerRoom,
    bool? rentsVests,
    bool? rentsBalls,
    double? pricePerHour,
  }) async {
    final resp = await _api.patchAutenticado(
      '/venues/$venueId',
      token: token,
      corpo: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (address != null) 'address': address,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (covered != null) 'covered': covered,
        if (hasParking != null) 'hasParking': hasParking,
        if (hasBar != null) 'hasBar': hasBar,
        if (hasLockerRoom != null) 'hasLockerRoom': hasLockerRoom,
        if (rentsVests != null) 'rentsVests': rentsVests,
        if (rentsBalls != null) 'rentsBalls': rentsBalls,
        if (pricePerHour != null) 'pricePerHour': pricePerHour,
      },
    );
    return Venue.fromJson(resp);
  }

  Future<VenueSlot> criarSlot(
    String venueId,
    String token, {
    required int weekday,
    required String startTime,
    required String endTime,
    required double price,
  }) async {
    final resp = await _api.postAutenticado(
      '/venues/$venueId/slots',
      token: token,
      corpo: {
        'weekday': weekday,
        'startTime': startTime,
        'endTime': endTime,
        'price': price,
      },
    );
    return VenueSlot.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> removerSlot(String venueId, String slotId, String token) {
    return _api.deleteAutenticado('/venues/$venueId/slots/$slotId', token: token);
  }

  Future<List<VenueSlot>> disponibilidade(String venueId, String data, String token) async {
    final lista = await _api.getLista('/venues/$venueId/availability?date=$data', token: token);
    return lista.map((s) => VenueSlot.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<Booking> reservar(String venueId, String slotId, String token, {required String data}) async {
    final resp = await _api.postAutenticado(
      '/venues/$venueId/slots/$slotId/bookings',
      token: token,
      corpo: {'date': data},
    );
    return Booking.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<Booking>> minhasReservas(String token) async {
    final lista = await _api.getLista('/bookings/mine', token: token);
    return lista.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<Booking> cancelarReserva(String bookingId, String token) async {
    final resp = await _api.deleteAutenticado('/bookings/$bookingId', token: token);
    return Booking.fromJson(resp);
  }

  /// Reservas recebidas na quadra — só o dono consegue chamar (o backend
  /// responde 403 pra qualquer outro usuário).
  Future<List<Booking>> reservasDaQuadra(String venueId, String token) async {
    final lista = await _api.getLista('/venues/$venueId/bookings', token: token);
    return lista.map((b) => Booking.fromJson(b as Map<String, dynamic>)).toList();
  }

  Future<Booking> atualizarStatusReserva(String bookingId, String token, {required String status}) async {
    final resp = await _api.patchAutenticado('/bookings/$bookingId/status', token: token, corpo: {'status': status});
    return Booking.fromJson(resp);
  }
}

import 'venue_slot.dart';

/// Espelha o Venue (`prisma/schema.prisma`). Não existe coluna de
/// cidade/estado dedicada — só `address` (texto livre); a busca por cidade
/// no backend filtra dentro desse mesmo campo. `slots` só vem preenchido em
/// `GET /venues/:id` (detalhe) — nas listagens (`GET /venues`, `GET
/// /venues/mine`) fica null.
class Venue {
  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final bool covered;
  final bool hasParking;
  final bool hasBar;
  final bool hasLockerRoom;
  final bool rentsVests;
  final bool rentsBalls;
  final double? pricePerHour;
  final double avgRating;
  final List<VenueSlot>? slots;

  Venue({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.lat,
    this.lng,
    required this.covered,
    required this.hasParking,
    required this.hasBar,
    required this.hasLockerRoom,
    required this.rentsVests,
    required this.rentsBalls,
    this.pricePerHour,
    required this.avgRating,
    this.slots,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        covered: json['covered'] as bool? ?? false,
        hasParking: json['hasParking'] as bool? ?? false,
        hasBar: json['hasBar'] as bool? ?? false,
        hasLockerRoom: json['hasLockerRoom'] as bool? ?? false,
        rentsVests: json['rentsVests'] as bool? ?? false,
        rentsBalls: json['rentsBalls'] as bool? ?? false,
        pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
        avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
        slots: (json['slots'] as List?)?.map((s) => VenueSlot.fromJson(s as Map<String, dynamic>)).toList(),
      );

  bool souDono(String userId) => ownerId == userId;

  /// `avgRating` nasce zerado e nunca é recalculado pelo backend (nenhum
  /// fluxo de avaliação existe ainda) — mostrar "0.0" seria dar a entender
  /// que a quadra foi avaliada e tirou nota mínima, o que não é verdade.
  bool get temAvaliacao => avgRating > 0;
}

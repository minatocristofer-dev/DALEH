/// Espelha o Booking (`prisma/schema.prisma`). Os campos `venueSlot*`/`venue*`
/// só vêm preenchidos em `GET /bookings/mine` e `GET /venues/:id/bookings`
/// (include aninhado); em `POST .../bookings` a resposta é o Booking cru, sem
/// esses campos. `bookedByUser*` só vem em `GET /venues/:id/bookings` (é o
/// dono vendo quem reservou) — `bookedById` continua sem relação Prisma de
/// verdade no backend, então esse nome vem resolvido à parte pelo service,
/// nunca em `GET /bookings/mine` (ali a reserva já é do próprio usuário).
class Booking {
  final String id;
  final String venueSlotId;
  final String bookedById;
  final DateTime date;
  final String status; // pending | confirmed | cancelled
  final String? venueSlotStartTime;
  final String? venueSlotEndTime;
  final double? venueSlotPrice;
  final String? venueName;
  final String? venueAddress;
  final String? bookedByUserFullName;
  final String? bookedByUserAvatarUrl;

  Booking({
    required this.id,
    required this.venueSlotId,
    required this.bookedById,
    required this.date,
    required this.status,
    this.venueSlotStartTime,
    this.venueSlotEndTime,
    this.venueSlotPrice,
    this.venueName,
    this.venueAddress,
    this.bookedByUserFullName,
    this.bookedByUserAvatarUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final venueSlot = json['venueSlot'] as Map<String, dynamic>?;
    final venue = venueSlot?['venue'] as Map<String, dynamic>?;
    final bookedByUser = json['bookedByUser'] as Map<String, dynamic>?;
    return Booking(
      id: json['id'] as String,
      venueSlotId: json['venueSlotId'] as String,
      bookedById: json['bookedById'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      venueSlotStartTime: venueSlot?['startTime'] as String?,
      venueSlotEndTime: venueSlot?['endTime'] as String?,
      venueSlotPrice: (venueSlot?['price'] as num?)?.toDouble(),
      venueName: venue?['name'] as String?,
      venueAddress: venue?['address'] as String?,
      bookedByUserFullName: bookedByUser?['fullName'] as String?,
      bookedByUserAvatarUrl: bookedByUser?['avatarUrl'] as String?,
    );
  }

  bool get pendente => status == 'pending';
  bool get confirmada => status == 'confirmed';
  bool get cancelada => status == 'cancelled';
}

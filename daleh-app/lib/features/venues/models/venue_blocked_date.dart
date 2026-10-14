/// Espelha o VenueBlockedDate (`prisma/schema.prisma`) — uma data em que o
/// dono tirou a quadra inteira de disponibilidade. Só aparece pra quem gerencia
/// a quadra; o jogador só vê o efeito (nenhum horário disponível naquele dia).
class VenueBlockedDate {
  final String id;
  final String venueId;
  final DateTime date;
  final String? reason;

  VenueBlockedDate({
    required this.id,
    required this.venueId,
    required this.date,
    this.reason,
  });

  factory VenueBlockedDate.fromJson(Map<String, dynamic> json) => VenueBlockedDate(
        id: json['id'] as String,
        venueId: json['venueId'] as String,
        date: DateTime.parse(json['date'] as String),
        reason: json['reason'] as String?,
      );
}

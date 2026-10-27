/// Espelha o VenueSlot (`prisma/schema.prisma`). `weekday`: 0=Segunda...6=Domingo
/// (mesma convenção do backend). `ocupado` só vem preenchido quando o slot
/// chega via `GET /venues/:id/availability` — em `GET /venues/:id` (slots do
/// detalhe da quadra) esse campo não existe, então fica null.
class VenueSlot {
  final String id;
  final String venueId;
  final int weekday;
  final String startTime;
  final String endTime;
  final double price;
  final bool isRecurring;
  final bool? ocupado;
  // Só vêm preenchidos via `GET /venues/:id/availability` (mesma regra de
  // `ocupado`) — horário fixo (recorrente) e quem reservou, pra Agenda do
  // Locador (QA Round 3).
  final bool fixo;
  final String? fixedTeamName;
  final String? bookingId;
  final String? reservadoPorNome;

  VenueSlot({
    required this.id,
    required this.venueId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isRecurring,
    this.ocupado,
    this.fixo = false,
    this.fixedTeamName,
    this.bookingId,
    this.reservadoPorNome,
  });

  factory VenueSlot.fromJson(Map<String, dynamic> json) => VenueSlot(
        id: json['id'] as String,
        venueId: json['venueId'] as String,
        weekday: json['weekday'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        price: (json['price'] as num).toDouble(),
        isRecurring: json['isRecurring'] as bool? ?? true,
        ocupado: json['ocupado'] as bool?,
        fixo: json['fixo'] as bool? ?? false,
        fixedTeamName: json['fixedTeamName'] as String?,
        bookingId: json['bookingId'] as String?,
        reservadoPorNome: json['reservadoPorNome'] as String?,
      );
}

const diasDaSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

String nomeDoDia(int weekday) => (weekday >= 0 && weekday <= 6) ? diasDaSemana[weekday] : '—';

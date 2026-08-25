import 'package:flutter/material.dart';
import '../../features/venues/models/booking.dart';
import '../../theme/daleh_theme.dart';
import 'primary_button.dart';
import 'status_chip.dart';

String _dataFormatada(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class BookingCard extends StatelessWidget {
  final Booking reserva;
  final VoidCallback? onCancelar;
  final bool cancelando;

  const BookingCard({super.key, required this.reserva, this.onCancelar, this.cancelando = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reserva.venueName ?? 'Quadra',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                StatusChip(texto: _rotulo(reserva.status), cor: _cor(reserva.status)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: DalehColors.muted),
                const SizedBox(width: 6),
                Text(_dataFormatada(reserva.date), style: const TextStyle(fontSize: 13)),
                if (reserva.venueSlotStartTime != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14, color: DalehColors.muted),
                  const SizedBox(width: 6),
                  Text('${reserva.venueSlotStartTime} – ${reserva.venueSlotEndTime}', style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
            if (reserva.venueAddress != null && reserva.venueAddress!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place, size: 14, color: DalehColors.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(reserva.venueAddress!, style: const TextStyle(fontSize: 12, color: DalehColors.muted))),
                ],
              ),
            ],
            if (onCancelar != null && !reserva.cancelada) ...[
              const SizedBox(height: 12),
              PrimaryButton(label: 'Cancelar reserva', onPressed: onCancelar, carregando: cancelando),
            ],
          ],
        ),
      ),
    );
  }

  String _rotulo(String status) {
    switch (status) {
      case 'confirmed':
        return 'CONFIRMADA';
      case 'cancelled':
        return 'CANCELADA';
      default:
        return 'PENDENTE';
    }
  }

  Color _cor(String status) {
    switch (status) {
      case 'confirmed':
        return DalehColors.turf;
      case 'cancelled':
        return DalehColors.danger;
      default:
        return DalehColors.amber;
    }
  }
}

import 'package:flutter/material.dart';
import '../../features/venues/models/venue_slot.dart';
import '../../theme/daleh_theme.dart';
import 'status_chip.dart';

/// Uma linha de horário na tela de disponibilidade — o backend é quem decide
/// `ocupado` (não recalculamos isso no Flutter).
class VenueSlotTile extends StatelessWidget {
  final VenueSlot slot;
  final VoidCallback? onTap;

  const VenueSlotTile({super.key, required this.slot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ocupado = slot.ocupado ?? false;
    return Card(
      shape: ocupado
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: DalehColors.turf.withValues(alpha: 0.3)),
            ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: ocupado ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: DalehColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${slot.startTime} – ${slot.endTime}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('R\$${slot.price.toStringAsFixed(0)}', style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(
                texto: ocupado ? 'OCUPADO' : 'DISPONÍVEL',
                cor: ocupado ? DalehColors.danger : DalehColors.turf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

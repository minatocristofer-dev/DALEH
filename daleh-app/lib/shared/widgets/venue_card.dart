import 'package:flutter/material.dart';
import '../../features/venues/models/venue.dart';
import '../../theme/daleh_theme.dart';
import 'crest_avatar.dart';

class VenueCard extends StatelessWidget {
  final Venue quadra;
  final VoidCallback onTap;

  const VenueCard({super.key, required this.quadra, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CrestAvatar(url: null, nome: quadra.name, tamanho: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quadra.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quadra.address != null && quadra.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        quadra.address!,
                        style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        if (quadra.pricePerHour != null)
                          _atributo(Icons.attach_money, 'R\$${quadra.pricePerHour!.toStringAsFixed(0)}/h'),
                        if (quadra.covered) _atributo(Icons.roofing, 'Coberta'),
                        if (quadra.hasParking) _atributo(Icons.local_parking, 'Estacionamento'),
                        if (quadra.hasLockerRoom) _atributo(Icons.checkroom, 'Vestiário'),
                        if (quadra.hasBar) _atributo(Icons.local_bar, 'Bar'),
                        if (quadra.rentsVests) _atributo(Icons.checkroom_outlined, 'Aluga colete'),
                        if (quadra.rentsBalls) _atributo(Icons.sports_soccer, 'Aluga bola'),
                        if (quadra.temAvaliacao) _atributo(Icons.star, quadra.avgRating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: DalehColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atributo(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: DalehColors.muted),
        const SizedBox(width: 3),
        Text(texto, style: const TextStyle(color: DalehColors.muted, fontSize: 11)),
      ],
    );
  }
}

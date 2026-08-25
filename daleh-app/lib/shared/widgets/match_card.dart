import 'package:flutter/material.dart';
import '../../features/matches/models/match.dart';
import '../../theme/daleh_theme.dart';
import 'status_chip.dart';

String _dataHoraFormatada(DateTime d) {
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  final hora = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${d.year} às $hora:$min';
}

class MatchCard extends StatelessWidget {
  final Match partida;
  final VoidCallback onTap;

  const MatchCard({super.key, required this.partida, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      partida.temTimes
                          ? '${partida.homeTeamName ?? 'Time A'} x ${partida.awayTeamName ?? 'Time B'}'
                          : (partida.modalidadeLabel ?? 'Partida'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  if (partida.visibility == 'private') const StatusChip(texto: 'PRIVADA', cor: DalehColors.muted),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: DalehColors.muted),
                  const SizedBox(width: 6),
                  Text(_dataHoraFormatada(partida.scheduledAt), style: const TextStyle(fontSize: 13)),
                ],
              ),
              if (partida.venueName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: DalehColors.muted),
                    const SizedBox(width: 6),
                    Text(partida.venueName!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (partida.totalConfirmados != null) ...[
                    const Icon(Icons.groups, size: 14, color: DalehColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${partida.totalConfirmados}${partida.maxPlayers != null ? '/${partida.maxPlayers}' : ''} confirmados',
                      style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  StatusChip(texto: _rotuloStatus(partida.status), cor: _corStatus(partida.status)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rotuloStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'EM ANDAMENTO';
      case 'finished':
        return 'FINALIZADA';
      case 'cancelled':
        return 'CANCELADA';
      default:
        return 'AGENDADA';
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'in_progress':
        return DalehColors.amber;
      case 'finished':
        return DalehColors.muted;
      case 'cancelled':
        return DalehColors.danger;
      default:
        return DalehColors.turf;
    }
  }
}

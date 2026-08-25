import 'package:flutter/material.dart';
import '../../features/teams/models/team.dart';
import '../../theme/daleh_theme.dart';
import 'crest_avatar.dart';
import 'status_chip.dart';

class TeamCard extends StatelessWidget {
  final Team time;
  final bool souDono;
  final VoidCallback onTap;

  const TeamCard({super.key, required this.time, required this.souDono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final localizacao = [time.city, time.state].where((v) => v != null && v.isNotEmpty).join(' / ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CrestAvatar(url: time.crestUrl, nome: time.name, tamanho: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time.name,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (localizacao.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(localizacao, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (time.meuPapel != null) StatusChip.papel(time.meuPapel!, souDono: souDono),
                        if (time.totalMembros != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.groups, size: 14, color: DalehColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            '${time.totalMembros} ${time.totalMembros == 1 ? 'jogador' : 'jogadores'}',
                            style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                          ),
                        ],
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
}

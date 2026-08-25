import 'package:flutter/material.dart';
import '../../features/perfil/perfil_publico_screen.dart';
import '../../features/teams/models/call_up.dart';
import '../../theme/daleh_theme.dart';
import 'crest_avatar.dart';
import 'primary_button.dart';
import 'status_chip.dart';

String _dataFormatada(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class CallUpCard extends StatelessWidget {
  final CallUp callUp;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;
  final bool carregandoAcao;

  const CallUpCard({
    super.key,
    required this.callUp,
    this.onConfirmar,
    this.onRecusar,
    this.carregandoAcao = false,
  });

  @override
  Widget build(BuildContext context) {
    final mostrarAcoes = callUp.pendente && (onConfirmar != null || onRecusar != null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: callUp.userId)),
                    ),
                    child: Row(
                      children: [
                        if (callUp.teamName != null) ...[
                          CrestAvatar(url: callUp.teamCrestUrl, nome: callUp.teamName!, tamanho: 36),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                callUp.teamName ?? 'Convocação',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                              if (callUp.userFullName != null)
                                Text(callUp.userFullName!, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StatusChip.convocacao(callUp.status),
              ],
            ),
            const SizedBox(height: 12),
            _linha(Icons.place, callUp.venueNameSnapshot),
            const SizedBox(height: 6),
            _linha(Icons.calendar_today, '${_dataFormatada(callUp.scheduledDate)} às ${callUp.scheduledTime}'),
            if (mostrarAcoes) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onRecusar != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: carregandoAcao ? null : onRecusar,
                        child: const Text('Recusar'),
                      ),
                    ),
                  if (onRecusar != null && onConfirmar != null) const SizedBox(width: 10),
                  if (onConfirmar != null)
                    Expanded(
                      child: PrimaryButton(label: 'Confirmar', onPressed: onConfirmar, carregando: carregandoAcao),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linha(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 14, color: DalehColors.muted),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

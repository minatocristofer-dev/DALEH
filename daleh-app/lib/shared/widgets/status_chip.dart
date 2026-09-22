import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

class StatusChip extends StatelessWidget {
  final String texto;
  final Color cor;

  const StatusChip({super.key, required this.texto, required this.cor});

  /// Papéis vêm exatamente do enum PapelTime do backend — não inventar rótulo novo.
  factory StatusChip.papel(String papel, {required bool souDono}) {
    if (souDono) return const StatusChip(texto: 'ADMINISTRADOR', cor: DalehColors.amber);
    switch (papel) {
      case 'CAPITAO':
        return const StatusChip(texto: 'CAPITÃO', cor: DalehColors.turf);
      case 'VICE_CAPITAO':
        return const StatusChip(texto: 'VICE-CAPITÃO', cor: DalehColors.turfDim);
      case 'TESOUREIRO':
        return const StatusChip(texto: 'TESOUREIRO', cor: DalehColors.amber);
      default:
        return const StatusChip(texto: 'JOGADOR', cor: DalehColors.muted);
    }
  }

  /// Status vêm exatamente do enum CallUpStatus do backend (PENDENTE | CONFIRMADO | RECUSADO).
  factory StatusChip.convocacao(String status) {
    switch (status) {
      case 'CONFIRMADO':
        return const StatusChip(texto: 'CONFIRMADO', cor: DalehColors.turf);
      case 'RECUSADO':
        return const StatusChip(texto: 'RECUSADO', cor: DalehColors.danger);
      default:
        return const StatusChip(texto: 'PENDENTE', cor: DalehColors.amber);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withOpacity(0.5)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}

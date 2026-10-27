import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

const diasDaSemanaAbreviado = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Faixa horizontal de 14 dias a partir de hoje, com o dia selecionado em
/// lime — usada tanto na reserva de quadra (Jogador) quanto no painel do
/// Locador (QA Round 3, item 1.1: "reaproveitar dados existentes, não criar
/// fluxo paralelo").
class FaixaDeDias extends StatelessWidget {
  final DateTime selecionado;
  final ValueChanged<DateTime> onSelecionar;
  final VoidCallback? onEscolherOutraData;
  const FaixaDeDias({super.key, required this.selecionado, required this.onSelecionar, this.onEscolherOutraData});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final dias = List.generate(14, (i) => DateTime(hoje.year, hoje.month, hoje.day + i));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dias.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final dia = dias[i];
                  final sel = mesmoDia(dia, selecionado);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelecionar(dia),
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: sel ? DalehColors.turf : DalehColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? DalehColors.turf : DalehColors.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            diasDaSemanaAbreviado[dia.weekday % 7],
                            style: TextStyle(
                              color: sel ? DalehColors.bg : DalehColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dia.day}',
                            style: TextStyle(
                              color: sel ? DalehColors.bg : DalehColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (onEscolherOutraData != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEscolherOutraData,
              tooltip: 'Escolher outra data',
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ],
        ],
      ),
    );
  }
}

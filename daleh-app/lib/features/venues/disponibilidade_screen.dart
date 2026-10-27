import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/faixa_de_dias.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/venue_slot_tile.dart';
import 'models/venue_slot.dart';
import 'venues_providers.dart';

String _dataIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _dataFormatada(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class DisponibilidadeScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  const DisponibilidadeScreen({super.key, required this.venueId, required this.venueName});

  @override
  ConsumerState<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends ConsumerState<DisponibilidadeScreen> {
  DateTime _data = DateTime.now();
  bool _reservando = false;

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365)),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  DisponibilidadeQuery get _query => (venueId: widget.venueId, data: _dataIso(_data));

  Future<void> _confirmarReserva(VenueSlot slot) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar reserva?'),
        content: Text('${_dataFormatada(_data)}, ${slot.startTime} – ${slot.endTime}, R\$${slot.price.toStringAsFixed(0)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _reservando = true);
    try {
      await ref.read(venuesActionsProvider).reservar(widget.venueId, slot.id, data: _query.data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva feita! Confira em "Minhas reservas".')));
      }
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.conflict) {
        ref.invalidate(disponibilidadeProvider(_query));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Esse horário acabou de ser reservado por outra pessoa. Escolhe outro.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _reservando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibilidadeAsync = ref.watch(disponibilidadeProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(widget.venueName)),
      body: Column(
        children: [
          FaixaDeDias(selecionado: _data, onSelecionar: (d) => setState(() => _data = d), onEscolherOutraData: _escolherData),
          Expanded(
            child: disponibilidadeAsync.when(
              loading: () => const LoadingState(mensagem: 'Carregando horários...'),
              error: (erro, _) => ListView(
                children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(disponibilidadeProvider(_query)))],
              ),
              data: (slots) {
                if (slots.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 40),
                      EmptyState(
                        icon: Icons.event_busy,
                        titulo: 'Sem horários nesse dia',
                        subtitulo: 'Essa quadra não tem grade cadastrada pra esse dia da semana.',
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: slots.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _reservando
                        ? Opacity(opacity: 0.6, child: VenueSlotTile(slot: slots[i]))
                        : VenueSlotTile(slot: slots[i], onTap: () => _confirmarReserva(slots[i])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

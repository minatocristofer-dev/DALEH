import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/booking_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import '../perfil/perfil_publico_screen.dart';
import 'models/booking.dart';
import 'models/venue.dart';
import 'models/venue_slot.dart';
import 'venue_form_screen.dart';
import 'venues_providers.dart';

class MinhaQuadraDetailScreen extends ConsumerWidget {
  final String venueId;
  final int abaInicial;
  const MinhaQuadraDetailScreen({super.key, required this.venueId, this.abaInicial = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadraAsync = ref.watch(quadraDetalheProvider(venueId));

    return DefaultTabController(
      length: 2,
      initialIndex: abaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: Text(quadraAsync.maybeWhen(data: (v) => v.name, orElse: () => 'Minha quadra')),
          actions: [
            quadraAsync.maybeWhen(
              data: (quadra) => IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VenueFormScreen(quadraParaEditar: quadra)),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'HORÁRIOS'), Tab(text: 'RESERVAS')]),
        ),
        body: quadraAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(quadraDetalheProvider(venueId))),
          data: (quadra) => TabBarView(
            children: [
              _HorariosBody(quadra: quadra),
              _ReservasRecebidasBody(venueId: venueId),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservasRecebidasBody extends ConsumerStatefulWidget {
  final String venueId;
  const _ReservasRecebidasBody({required this.venueId});

  @override
  ConsumerState<_ReservasRecebidasBody> createState() => _ReservasRecebidasBodyState();
}

class _ReservasRecebidasBodyState extends ConsumerState<_ReservasRecebidasBody> {
  String? _emAcaoId;

  Future<void> _confirmar(Booking reserva) async {
    setState(() => _emAcaoId = reserva.id);
    try {
      await ref.read(venuesActionsProvider).confirmarReserva(widget.venueId, reserva.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _emAcaoId = null);
    }
  }

  Future<void> _recusar(Booking reserva) async {
    setState(() => _emAcaoId = reserva.id);
    try {
      await ref.read(venuesActionsProvider).recusarReserva(widget.venueId, reserva.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _emAcaoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasAsync = ref.watch(reservasDaQuadraProvider(widget.venueId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reservasDaQuadraProvider(widget.venueId)),
      child: reservasAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [
            ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(reservasDaQuadraProvider(widget.venueId))),
          ],
        ),
        data: (reservas) {
          if (reservas.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icon: Icons.inbox_outlined,
                  titulo: 'Nenhuma reserva recebida ainda',
                  subtitulo: 'Quando alguém reservar essa quadra, aparece aqui.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, i) {
              final r = reservas[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReservaRecebidaCard(
                  reserva: r,
                  emAcao: _emAcaoId == r.id,
                  onConfirmar: r.pendente ? () => _confirmar(r) : null,
                  onRecusar: r.pendente ? () => _recusar(r) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReservaRecebidaCard extends StatelessWidget {
  final Booking reserva;
  final bool emAcao;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;

  const _ReservaRecebidaCard({
    required this.reserva,
    required this.emAcao,
    this.onConfirmar,
    this.onRecusar,
  });

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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: reserva.bookedById)),
                    ),
                    child: Text(
                      reserva.bookedByUserFullName ?? 'Jogador',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BookingCard(reserva: reserva),
            if (onConfirmar != null || onRecusar != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (onRecusar != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: emAcao ? null : onRecusar,
                        child: const Text('Recusar'),
                      ),
                    ),
                  if (onRecusar != null && onConfirmar != null) const SizedBox(width: 10),
                  if (onConfirmar != null)
                    Expanded(
                      child: PrimaryButton(label: 'Confirmar', onPressed: onConfirmar, carregando: emAcao),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HorariosBody extends ConsumerWidget {
  final Venue quadra;
  const _HorariosBody({required this.quadra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = [...(quadra.slots ?? const <VenueSlot>[])]..sort((a, b) => a.weekday.compareTo(b.weekday));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarAdicionarHorario(context, ref),
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar horário'),
      ),
      body: slots.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icon: Icons.event_note_outlined,
                  titulo: 'Nenhum horário cadastrado',
                  subtitulo: 'Adicione os horários em que essa quadra fica disponível pra reserva.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: slots.length,
              separatorBuilder: (_, _) => const Divider(color: DalehColors.line),
              itemBuilder: (context, i) {
                final slot = slots[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: DalehColors.turf),
                  title: Text('${nomeDoDia(slot.weekday)} · ${slot.startTime} – ${slot.endTime}'),
                  subtitle: Text('R\$${slot.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: DalehColors.danger),
                    onPressed: () => _confirmarRemocao(context, ref, slot),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmarRemocao(BuildContext context, WidgetRef ref, VenueSlot slot) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover horário?'),
        content: Text('${nomeDoDia(slot.weekday)}, ${slot.startTime} – ${slot.endTime}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover', style: TextStyle(color: DalehColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(venuesActionsProvider).removerSlot(quadra.id, slot.id);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _mostrarAdicionarHorario(BuildContext context, WidgetRef ref) async {
    int weekday = 0;
    final inicioCtrl = TextEditingController();
    final fimCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    var enviando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DalehColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Adicionar horário', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: weekday,
                    decoration: const InputDecoration(labelText: 'Dia da semana'),
                    items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(nomeDoDia(i)))),
                    onChanged: (v) => setState(() => weekday = v ?? weekday),
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Início (ex: 18:00)')),
                  const SizedBox(height: 14),
                  TextField(controller: fimCtrl, decoration: const InputDecoration(labelText: 'Fim (ex: 19:00)')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: precoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Adicionar',
                    carregando: enviando,
                    onPressed: () async {
                      final preco = double.tryParse(precoCtrl.text.trim().replaceAll(',', '.'));
                      if (inicioCtrl.text.trim().isEmpty || fimCtrl.text.trim().isEmpty || preco == null) {
                        setState(() => erro = 'Preencha início, fim e preço corretamente.');
                        return;
                      }
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(venuesActionsProvider).criarSlot(
                              quadra.id,
                              weekday: weekday,
                              startTime: inicioCtrl.text.trim(),
                              endTime: fimCtrl.text.trim(),
                              price: preco,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } on ApiException catch (e) {
                        setState(() {
                          erro = e.message;
                          enviando = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

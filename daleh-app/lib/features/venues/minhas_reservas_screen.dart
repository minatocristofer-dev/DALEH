import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/booking_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import 'venues_providers.dart';

class MinhasReservasScreen extends ConsumerStatefulWidget {
  const MinhasReservasScreen({super.key});

  @override
  ConsumerState<MinhasReservasScreen> createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends ConsumerState<MinhasReservasScreen> {
  String? _cancelandoId;

  Future<void> _cancelar(String bookingId) async {
    setState(() => _cancelandoId = bookingId);
    try {
      await ref.read(venuesActionsProvider).cancelarReserva(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cancelandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasAsync = ref.watch(minhasReservasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas reservas')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(minhasReservasProvider),
        child: reservasAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(minhasReservasProvider))],
          ),
          data: (reservas) {
            if (reservas.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    titulo: 'Nenhuma reserva ainda',
                    subtitulo: 'Quando você reservar uma quadra, ela aparece aqui.',
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
                  child: BookingCard(
                    reserva: r,
                    cancelando: _cancelandoId == r.id,
                    onCancelar: r.cancelada ? null : () => _cancelar(r.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

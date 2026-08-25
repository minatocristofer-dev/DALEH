import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'disponibilidade_screen.dart';
import 'models/venue.dart';
import 'venues_providers.dart';

class VenueDetailScreen extends ConsumerWidget {
  final String venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadraAsync = ref.watch(quadraDetalheProvider(venueId));

    return Scaffold(
      appBar: AppBar(title: Text(quadraAsync.maybeWhen(data: (v) => v.name, orElse: () => 'Quadra'))),
      body: quadraAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(quadraDetalheProvider(venueId))),
        data: (quadra) => _VenueDetailBody(quadra: quadra),
      ),
    );
  }
}

class _VenueDetailBody extends StatelessWidget {
  final Venue quadra;
  const _VenueDetailBody({required this.quadra});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: CrestAvatar(url: null, nome: quadra.name, tamanho: 84)),
        const SizedBox(height: 16),
        Center(
          child: Text(quadra.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22), textAlign: TextAlign.center),
        ),
        if (quadra.address != null && quadra.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(child: Text(quadra.address!, style: const TextStyle(color: DalehColors.muted), textAlign: TextAlign.center)),
        ],
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quadra.pricePerHour != null) _linha(Icons.attach_money, 'Preço por hora', 'R\$${quadra.pricePerHour!.toStringAsFixed(2)}'),
                if (quadra.temAvaliacao) _linha(Icons.star, 'Avaliação', quadra.avgRating.toStringAsFixed(1)),
                _linhaBool(Icons.roofing, 'Quadra coberta', quadra.covered),
                _linhaBool(Icons.local_parking, 'Estacionamento', quadra.hasParking),
                _linhaBool(Icons.checkroom, 'Vestiário', quadra.hasLockerRoom),
                _linhaBool(Icons.local_bar, 'Bar', quadra.hasBar),
                _linhaBool(Icons.checkroom_outlined, 'Aluga colete', quadra.rentsVests),
                _linhaBool(Icons.sports_soccer, 'Aluga bola', quadra.rentsBalls),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'VER DISPONIBILIDADE',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DisponibilidadeScreen(venueId: quadra.id, venueName: quadra.name)),
          ),
        ),
      ],
    );
  }

  Widget _linha(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DalehColors.turf),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _linhaBool(IconData icon, String label, bool valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: valor ? DalehColors.turf : DalehColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: valor ? DalehColors.text : DalehColors.muted))),
          Icon(valor ? Icons.check_circle : Icons.cancel_outlined, size: 18, color: valor ? DalehColors.turf : DalehColors.muted),
        ],
      ),
    );
  }
}

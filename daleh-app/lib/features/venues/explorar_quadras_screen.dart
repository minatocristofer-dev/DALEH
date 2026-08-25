import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/venue_card.dart';
import 'minhas_quadras_screen.dart';
import 'minhas_reservas_screen.dart';
import 'venue_detail_screen.dart';
import 'venues_providers.dart';

class ExplorarQuadrasScreen extends ConsumerWidget {
  const ExplorarQuadrasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrasAsync = ref.watch(quadrasPublicasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Quadras'),
        actions: [
          IconButton(
            tooltip: 'Minhas reservas',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MinhasReservasScreen())),
          ),
          IconButton(
            tooltip: 'Minhas quadras',
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MinhasQuadrasScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar por cidade ou endereço',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) => ref.read(filtroQuadrasProvider.notifier).state = v.trim(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(quadrasPublicasProvider),
              child: quadrasAsync.when(
                loading: () => const LoadingState(mensagem: 'Carregando quadras...'),
                error: (erro, _) => ListView(
                  children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(quadrasPublicasProvider))],
                ),
                data: (quadras) {
                  if (quadras.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.stadium_outlined,
                          titulo: 'Nenhuma quadra encontrada',
                          subtitulo: 'Tenta buscar por outra cidade ou remova o filtro.',
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: quadras.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VenueCard(
                        quadra: quadras[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => VenueDetailScreen(venueId: quadras[i].id)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

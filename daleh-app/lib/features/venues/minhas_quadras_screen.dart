import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/venue_card.dart';
import '../../theme/daleh_theme.dart';
import 'minha_quadra_detail_screen.dart';
import 'venue_form_screen.dart';
import 'venues_providers.dart';

/// Acessada de dois jeitos: a partir de "Explorar Quadras" (um jogador
/// comum que também é dono de uma quadra) e, direto, pelo `LocadorShell`
/// (quem entrou escolhendo o modo "Dono de quadra" no login). O conteúdo é
/// o mesmo — só muda quem fica em volta dele (`MinhasQuadrasBody`).
class MinhasQuadrasScreen extends StatelessWidget {
  const MinhasQuadrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas quadras')),
      body: const MinhasQuadrasBody(),
    );
  }
}

/// Lista de quadras do dono + botão de criar — um `Scaffold` próprio (pelo
/// FAB), pensado pra ficar dentro do `body` de outro `Scaffold` (funciona
/// normalmente no Flutter; é assim que dá pra reaproveitar o mesmo FAB tanto
/// aqui quanto no `LocadorShell`, sem duplicar a lógica da lista).
class MinhasQuadrasBody extends ConsumerWidget {
  const MinhasQuadrasBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadrasAsync = ref.watch(minhasQuadrasProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VenueFormScreen())),
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        icon: const Icon(Icons.add),
        label: const Text('Criar quadra'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(minhasQuadrasProvider),
        child: quadrasAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(minhasQuadrasProvider))],
          ),
          data: (quadras) {
            if (quadras.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.storefront_outlined,
                    titulo: 'Você ainda não cadastrou nenhuma quadra.',
                    subtitulo: 'Cadastre sua quadra pra começar a receber reservas.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: quadras.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VenueCard(
                  quadra: quadras[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => MinhaQuadraDetailScreen(venueId: quadras[i].id)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

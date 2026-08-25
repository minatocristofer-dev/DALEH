import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/match_card.dart';
import '../../theme/daleh_theme.dart';
import 'criar_jogo_screen.dart';
import 'jogo_detail_screen.dart';
import 'matches_providers.dart';

class MeusJogosTab extends ConsumerWidget {
  const MeusJogosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidasAsync = ref.watch(minhasPartidasProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CriarJogoScreen())),
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        icon: const Icon(Icons.add),
        label: const Text('Criar jogo'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(minhasPartidasProvider),
        child: partidasAsync.when(
          loading: () => const LoadingState(mensagem: 'Carregando seus jogos...'),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(minhasPartidasProvider))],
          ),
          data: (partidas) {
            if (partidas.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.sports_soccer_outlined,
                    titulo: 'Você ainda não tem nenhum jogo.',
                    subtitulo: 'Crie um jogo avulso ou entre em algum já existente pra começar.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: partidas.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(
                  partida: partidas[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => JogoDetailScreen(matchId: partidas[i].id)),
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

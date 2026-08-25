import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/team_card.dart';
import '../../theme/daleh_theme.dart';
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import 'criar_time_screen.dart';
import 'minhas_convocacoes_screen.dart';
import 'team_detail_screen.dart';
import 'teams_providers.dart';

class MeusTimesScreen extends ConsumerWidget {
  const MeusTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesAsync = ref.watch(meusTimesProvider);
    final meuUserId = ref.watch(meuUserIdProvider);

    final naoLidas = ref.watch(notificacoesNaoLidasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Times'),
        actions: [
          IconButton(
            tooltip: 'Minhas convocações',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MinhasConvocacoesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Notificações',
            icon: Badge(
              label: Text('$naoLidas'),
              isLabelVisible: naoLidas > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: timesAsync.maybeWhen(
        data: (times) => times.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _irParaCriarTime(context),
                backgroundColor: DalehColors.turf,
                foregroundColor: DalehColors.bg,
                icon: const Icon(Icons.add),
                label: const Text('Criar novo time'),
              ),
        orElse: () => null,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meusTimesProvider),
        child: timesAsync.when(
          loading: () => const LoadingState(mensagem: 'Carregando seus times...'),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meusTimesProvider))],
          ),
          data: (times) {
            if (times.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.shield_outlined,
                    titulo: 'Você ainda não tem um time.',
                    subtitulo: 'Crie seu time, monte seu elenco e comece a construir sua história.',
                    ctaLabel: 'CRIAR MEU TIME',
                    onCta: () => _irParaCriarTime(context),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: times.length,
              itemBuilder: (context, i) {
                final time = times[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamCard(
                    time: time,
                    souDono: meuUserId != null && time.souDono(meuUserId),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: time.id)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _irParaCriarTime(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CriarTimeScreen()));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/call_up_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import 'teams_providers.dart';

class MinhasConvocacoesScreen extends ConsumerStatefulWidget {
  const MinhasConvocacoesScreen({super.key});

  @override
  ConsumerState<MinhasConvocacoesScreen> createState() => _MinhasConvocacoesScreenState();
}

class _MinhasConvocacoesScreenState extends ConsumerState<MinhasConvocacoesScreen> {
  String? _respondendoId;

  Future<void> _responder(String callUpId, String status) async {
    setState(() => _respondendoId = callUpId);
    try {
      await ref.read(teamsActionsProvider).responderConvocacao(callUpId, status);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _respondendoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final callUpsAsync = ref.watch(minhasConvocacoesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas convocações')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(minhasConvocacoesProvider),
        child: callUpsAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(minhasConvocacoesProvider))],
          ),
          data: (callUps) {
            if (callUps.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.campaign_outlined,
                    titulo: 'Nenhuma convocação por aqui',
                    subtitulo: 'Quando um time te convocar pra um jogo, aparece nessa lista.',
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: callUps.length,
              itemBuilder: (context, i) {
                final c = callUps[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CallUpCard(
                    callUp: c,
                    carregandoAcao: _respondendoId == c.id,
                    onConfirmar: c.pendente ? () => _responder(c.id, 'CONFIRMADO') : null,
                    onRecusar: c.pendente ? () => _responder(c.id, 'RECUSADO') : null,
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

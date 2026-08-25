import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import 'perfil_providers.dart';
import 'widgets/player_card_com_compartilhar.dart';

/// Perfil público de outro jogador (Fase 7) — qualquer usuário autenticado
/// pode abrir, sem exigir time/jogo em comum (`GET /users/:id`). Mesma
/// composição da tela do próprio perfil (`PerfilScreen`), só sem o botão
/// "Sair" — aqui reaproveita `PlayerCardComCompartilhar` por completo.
class PerfilPublicoScreen extends ConsumerWidget {
  final String userId;
  const PerfilPublicoScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilPublicoProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do jogador')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(perfilPublicoProvider(userId)),
        child: perfilAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [
              ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(perfilPublicoProvider(userId))),
            ],
          ),
          data: (perfil) => ListView(
            padding: const EdgeInsets.all(20),
            children: [PlayerCardComCompartilhar(perfil: perfil)],
          ),
        ),
      ),
    );
  }
}

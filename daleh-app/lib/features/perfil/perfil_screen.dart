import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../auth/auth_controller.dart';
import 'perfil_providers.dart';
import 'widgets/player_card_com_compartilhar.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(meuPerfilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meuPerfilProvider),
        child: perfilAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meuPerfilProvider))],
          ),
          data: (perfil) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PlayerCardComCompartilhar(perfil: perfil),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).sair(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

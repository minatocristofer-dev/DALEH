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
      appBar: AppBar(
        title: const Text('Perfil'),
        // "Sair" precisa estar sempre acessível, mesmo se o perfil não
        // carregar (erro de rede/servidor) — antes só existia dentro do
        // conteúdo carregado, deixando o usuário sem nenhum jeito de sair
        // da conta quando o `GET /auth/me` falhava.
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meuPerfilProvider),
        child: perfilAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meuPerfilProvider))],
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

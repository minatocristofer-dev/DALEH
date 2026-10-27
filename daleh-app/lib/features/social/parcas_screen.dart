import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../theme/daleh_theme.dart';
import '../perfil/perfil_publico_screen.dart';
import 'models/parca.dart';
import 'parcas_providers.dart';

/// "Parças" — MVP de seguir outro jogador: duas listas (quem você segue,
/// quem te segue), sem feed/chat/DM.
class ParcasScreen extends StatelessWidget {
  const ParcasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Parças'),
          bottom: const TabBar(tabs: [Tab(text: 'SEGUINDO'), Tab(text: 'SEGUIDORES')]),
        ),
        body: TabBarView(
          children: [
            _ListaParcas(provider: seguindoProvider, vazio: 'Você ainda não segue nenhum jogador.'),
            _ListaParcas(provider: seguidoresProvider, vazio: 'Ninguém te segue ainda.'),
          ],
        ),
      ),
    );
  }
}

class _ListaParcas extends ConsumerWidget {
  final AutoDisposeFutureProvider<List<Parca>> provider;
  final String vazio;
  const _ListaParcas({required this.provider, required this.vazio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcasAsync = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: parcasAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(provider))],
        ),
        data: (parcas) {
          if (parcas.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                EmptyState(icon: Icons.group_outlined, titulo: 'Nada por aqui', subtitulo: vazio),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(DalehSpacing.lg),
            itemCount: parcas.length,
            separatorBuilder: (_, _) => const SizedBox(height: DalehSpacing.sm),
            itemBuilder: (context, i) {
              final parca = parcas[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CrestAvatar(url: parca.avatarUrl, nome: parca.nomeExibido, tamanho: 40),
                  title: Text(parca.nomeExibido, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: parca.nickname != null ? Text(parca.fullName, style: const TextStyle(fontSize: 12)) : null,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: parca.id))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

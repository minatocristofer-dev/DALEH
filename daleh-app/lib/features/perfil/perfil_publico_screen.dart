import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../theme/daleh_theme.dart';
import '../social/parcas_providers.dart';
import 'perfil_providers.dart';
import 'widgets/player_card_com_compartilhar.dart';

/// Perfil público de outro jogador (Fase 7) — qualquer usuário autenticado
/// pode abrir, sem exigir time/jogo em comum (`GET /users/:id`). Mesma
/// composição da tela do próprio perfil (`PerfilScreen`), só sem o botão
/// "Sair" — aqui reaproveita `PlayerCardComCompartilhar` por completo, com
/// o botão de seguir/deixar de seguir ("Parças") logo abaixo.
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
            children: [
              PlayerCardComCompartilhar(perfil: perfil),
              const SizedBox(height: DalehSpacing.lg),
              _BotaoSeguir(userId: userId),
            ],
          ),
        ),
      ),
    );
  }
}

// Estado local otimista (não busca o status inicial de "já sigo ou não" —
// MVP simples, sem provider novo lido no build pra não exigir sessão
// Supabase inicializada só pra abrir a tela; `comSessao` só entra em ação
// quando o jogador de fato toca no botão).
class _BotaoSeguir extends ConsumerStatefulWidget {
  final String userId;
  const _BotaoSeguir({required this.userId});

  @override
  ConsumerState<_BotaoSeguir> createState() => _BotaoSeguirState();
}

class _BotaoSeguirState extends ConsumerState<_BotaoSeguir> {
  bool? _seguindo; // null = ainda não sabemos (mostra "Seguir" por padrão)
  bool _carregando = false;

  Future<void> _alternar() async {
    setState(() => _carregando = true);
    final jaSeguia = _seguindo == true;
    try {
      final acoes = ref.read(parcasActionsProvider);
      if (jaSeguia) {
        await acoes.deixarDeSeguir(widget.userId);
      } else {
        await acoes.seguir(widget.userId);
      }
      if (!mounted) return;
      setState(() => _seguindo = !jaSeguia);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seguindo = _seguindo == true;
    return OutlinedButton.icon(
      onPressed: _carregando ? null : _alternar,
      icon: Icon(seguindo ? Icons.person_remove_outlined : Icons.person_add_alt_1_outlined),
      label: Text(seguindo ? 'DEIXAR DE SEGUIR' : 'SEGUIR (PARÇA)'),
    );
  }
}

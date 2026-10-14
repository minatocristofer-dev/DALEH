import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/team_card.dart';
import '../../theme/daleh_theme.dart';
import '../auth/auth_controller.dart';
import '../matches/jogos_root_screen.dart';
import '../teams/criar_time_screen.dart';
import '../teams/models/team.dart';
import '../teams/models/team_member.dart';
import '../teams/team_detail_screen.dart';
import '../teams/teams_providers.dart';

/// Navegação de quem escolheu "Dirigente" no Seletor de Modo. Escolher esse
/// modo NÃO torna ninguém gestor de time nenhum — só entra aqui quem o
/// backend já reconhece como dono/capitão/vice de pelo menos um time
/// (`Team.meuPapel`/`Team.souDono`, os mesmos dados de `GET /teams/mine`).
/// As telas de time/jogos aqui dentro são as MESMAS do modo Jogador
/// (`TeamDetailScreen`, `JogosRootScreen`) — o que muda é só a navegação em
/// volta; a autorização de cada ação (editar elenco, finalizar partida etc.)
/// continua sendo decidida pelo backend dentro dessas telas.
bool timeEhGerenciavelPor(Team time, String? meuUserId) {
  if (meuUserId == null) return false;
  if (time.souDono(meuUserId)) return true;
  return time.meuPapel != null && papeisDeGestao.contains(time.meuPapel);
}

class DirigenteShell extends ConsumerStatefulWidget {
  const DirigenteShell({super.key});

  @override
  ConsumerState<DirigenteShell> createState() => _DirigenteShellState();
}

class _DirigenteShellState extends ConsumerState<DirigenteShell> {
  String? _timeSelecionadoId;
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final timesAsync = ref.watch(meusTimesProvider);
    final meuUserId = ref.watch(meuUserIdProvider);

    return timesAsync.when(
      loading: () => const Scaffold(body: LoadingState(mensagem: 'Carregando seus times...')),
      error: (erro, _) => Scaffold(
        appBar: AppBar(title: const Text('Dirigente')),
        body: ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meusTimesProvider)),
      ),
      data: (times) {
        final gerenciaveis = times.where((t) => timeEhGerenciavelPor(t, meuUserId)).toList();

        if (gerenciaveis.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dirigente'),
              actions: [_acaoTrocarModo(), _acaoSair()],
            ),
            body: EmptyState(
              icon: Icons.workspace_premium_outlined,
              titulo: 'Você ainda não gerencia um time.',
              subtitulo: 'Crie seu time pra organizar jogos, convocações e elenco.',
              ctaLabel: 'CRIAR TIME',
              onCta: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CriarTimeScreen())),
            ),
          );
        }

        final timeId = _timeSelecionadoId ?? (gerenciaveis.length == 1 ? gerenciaveis.first.id : null);

        if (timeId == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Selecione o time'),
              actions: [_acaoTrocarModo(), _acaoSair()],
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gerenciaveis.length,
              itemBuilder: (context, i) {
                final time = gerenciaveis[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamCard(
                    time: time,
                    souDono: meuUserId != null && time.souDono(meuUserId),
                    onTap: () => setState(() => _timeSelecionadoId = time.id),
                  ),
                );
              },
            ),
          );
        }

        final time = gerenciaveis.firstWhere((t) => t.id == timeId, orElse: () => gerenciaveis.first);

        return Scaffold(
          body: IndexedStack(
            index: _aba,
            children: [
              _InicioDirigente(
                time: time,
                podeTrocarTime: gerenciaveis.length > 1,
                onTrocarTime: () => setState(() => _timeSelecionadoId = null),
                onIrParaTime: () => setState(() => _aba = 1),
                onIrParaJogos: () => setState(() => _aba = 2),
              ),
              TeamDetailScreen(teamId: time.id),
              const JogosRootScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _aba,
            onDestinationSelected: (i) => setState(() => _aba = i),
            backgroundColor: DalehColors.surface,
            elevation: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
              NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Time'),
              NavigationDestination(
                icon: Icon(Icons.sports_soccer_outlined),
                selectedIcon: Icon(Icons.sports_soccer),
                label: 'Jogos',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _acaoTrocarModo() => IconButton(
        tooltip: 'Trocar modo',
        icon: const Icon(Icons.swap_horiz),
        onPressed: () => ref.read(authControllerProvider.notifier).abrirSeletorDeModo(),
      );

  Widget _acaoSair() => IconButton(
        tooltip: 'Sair',
        icon: const Icon(Icons.logout),
        onPressed: () => ref.read(authControllerProvider.notifier).sair(),
      );
}

/// Resumo mínimo, só com dados que o app já tem (card do time + atalhos) —
/// nenhum feed/estatística nova foi inventado pra essa tela.
class _InicioDirigente extends ConsumerWidget {
  final Team time;
  final bool podeTrocarTime;
  final VoidCallback onTrocarTime;
  final VoidCallback onIrParaTime;
  final VoidCallback onIrParaJogos;

  const _InicioDirigente({
    required this.time,
    required this.podeTrocarTime,
    required this.onTrocarTime,
    required this.onIrParaTime,
    required this.onIrParaJogos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dirigente'),
        actions: [
          if (podeTrocarTime)
            IconButton(tooltip: 'Trocar time', icon: const Icon(Icons.sync_alt), onPressed: onTrocarTime),
          IconButton(
            tooltip: 'Trocar modo',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(authControllerProvider.notifier).abrirSeletorDeModo(),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CrestAvatar(url: time.crestUrl, nome: time.name, tamanho: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(time.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        if (time.totalMembros != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${time.totalMembros} ${time.totalMembros == 1 ? 'jogador no elenco' : 'jogadores no elenco'}',
                            style: const TextStyle(color: DalehColors.muted, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            tileColor: DalehColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.shield_outlined, color: DalehColors.turf),
            title: const Text('Ver time', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Elenco, convocações e financeiro', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onIrParaTime,
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: DalehColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const Icon(Icons.sports_soccer_outlined, color: DalehColors.turf),
            title: const Text('Ver jogos', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Próximos jogos e desafios/amistosos', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onIrParaJogos,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/match_card.dart';
import '../../theme/daleh_theme.dart';
import '../matches/jogo_detail_screen.dart';
import '../matches/jogos_root_screen.dart';
import '../matches/matches_providers.dart';
import '../matches/models/match.dart';
import '../notifications/models/app_notification.dart';
import '../notifications/notification_navigator.dart';
import '../notifications/notifications_providers.dart';
import '../notifications/notifications_screen.dart';
import '../teams/minhas_convocacoes_screen.dart';
import '../teams/teams_providers.dart';

/// Painel inicial de verdade (substitui o placeholder "Em breve"). Não cria
/// nenhum endpoint novo — só combina providers que outras abas já usam
/// (Jogos, Convocações, Notificações). Sem busca: não existe endpoint de
/// busca no backend ainda, então não simulamos um.
class InicioScreen extends ConsumerWidget {
  final void Function(int aba) onNavegarParaAba;
  const InicioScreen({super.key, required this.onNavegarParaAba});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidasAsync = ref.watch(minhasPartidasProvider);
    final convocacoesAsync = ref.watch(minhasConvocacoesProvider);
    final notificacoesAsync = ref.watch(notificationsProvider);
    final naoLidas = ref.watch(notificacoesNaoLidasProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(minhasPartidasProvider);
        ref.invalidate(minhasConvocacoesProvider);
        ref.invalidate(notificationsProvider);
        await Future.wait([
          ref.read(minhasPartidasProvider.future),
          ref.read(notificationsProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FALA, CRAQUE!', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, height: 1.12, color: DalehColors.text),
                      children: [
                        TextSpan(text: 'Pronto pra\n'),
                        TextSpan(text: 'mais um jogo?', style: TextStyle(color: DalehColors.turf)),
                      ],
                    ),
                  ),
                ],
              ),
              _SinoDeNotificacoes(naoLidas: naoLidas),
            ],
          ),
          const SizedBox(height: 28),
          _tituloSecao('PRÓXIMO JOGO'),
          const SizedBox(height: 10),
          partidasAsync.when(
            loading: () => const _CarregandoDiscreto(),
            error: (_, _) => const _AvisoDiscreto('Não deu pra carregar seus jogos agora.'),
            data: (partidas) {
              final proximo = _proximoJogo(partidas);
              if (proximo == null) {
                return const _AvisoDiscreto('Nenhum jogo agendado. Bora marcar um?');
              }
              return MatchCard(
                partida: proximo,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => JogoDetailScreen(matchId: proximo.id))),
              );
            },
          ),
          const SizedBox(height: 28),
          _tituloSecao('ACESSO RÁPIDO'),
          const SizedBox(height: 12),
          convocacoesAsync.when(
            loading: () => _gradeAcessoRapido(context, convocacoesPendentes: 0),
            error: (_, _) => _gradeAcessoRapido(context, convocacoesPendentes: 0),
            data: (convocacoes) => _gradeAcessoRapido(
              context,
              convocacoesPendentes: convocacoes.where((c) => c.pendente).length,
            ),
          ),
          const SizedBox(height: 28),
          _tituloSecao('ATIVIDADE RECENTE'),
          const SizedBox(height: 10),
          notificacoesAsync.when(
            loading: () => const _CarregandoDiscreto(),
            error: (_, _) => const _AvisoDiscreto('Não deu pra carregar suas notificações agora.'),
            data: (notificacoes) {
              if (notificacoes.isEmpty) return const _AvisoDiscreto('Nenhuma atividade ainda.');
              final recentes = notificacoes.take(5).toList();
              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < recentes.length; i++) ...[
                      if (i > 0) const Divider(color: DalehColors.line, height: 1),
                      _LinhaAtividade(notificacao: recentes[i]),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Match? _proximoJogo(List<Match> partidas) {
    final agora = DateTime.now();
    final futuras = partidas
        .where((p) => !p.partidaEncerrada && p.scheduledAt.isAfter(agora))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return futuras.isEmpty ? null : futuras.first;
  }

  Widget _tituloSecao(String texto) => Text(
        texto,
        style: const TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
      );

  Widget _gradeAcessoRapido(BuildContext context, {required int convocacoesPendentes}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _AcaoRapida(
          icon: Icons.campaign_outlined,
          label: 'Convocações',
          badge: convocacoesPendentes > 0 ? convocacoesPendentes : null,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MinhasConvocacoesScreen())),
        ),
        _AcaoRapida(
          icon: Icons.sports_soccer_outlined,
          label: 'Meus Jogos',
          onTap: () => onNavegarParaAba(2),
        ),
        _AcaoRapida(
          icon: Icons.shield_outlined,
          label: 'Times',
          onTap: () => onNavegarParaAba(1),
        ),
        _AcaoRapida(
          icon: Icons.explore_outlined,
          label: 'Quadras',
          onTap: () => onNavegarParaAba(3),
        ),
        _AcaoRapida(
          icon: Icons.handshake_outlined,
          label: 'Desafios',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const JogosRootScreen(abaInicial: 1))),
        ),
      ],
    );
  }
}

class _SinoDeNotificacoes extends StatelessWidget {
  final int naoLidas;
  const _SinoDeNotificacoes({required this.naoLidas});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, size: 26),
            if (naoLidas > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(color: DalehColors.turf, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    naoLidas > 9 ? '9+' : '$naoLidas',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DalehColors.bg, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AcaoRapida extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final VoidCallback onTap;
  const _AcaoRapida({required this.icon, required this.label, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DalehColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DalehColors.line),
                  ),
                  child: Icon(icon, color: DalehColors.turf),
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(color: DalehColors.amber, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: DalehColors.bg, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _LinhaAtividade extends ConsumerWidget {
  final AppNotification notificacao;
  const _LinhaAtividade({required this.notificacao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: Icon(
        notificacao.lida ? Icons.notifications_none : Icons.notifications,
        color: notificacao.lida ? DalehColors.muted : DalehColors.turf,
        size: 20,
      ),
      title: Text(notificacao.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(_tempoDecorrido(notificacao.createdAt), style: const TextStyle(color: DalehColors.muted, fontSize: 11)),
      onTap: () {
        if (!notificacao.lida) {
          ref.read(notificationsActionsProvider).marcarLida(notificacao.id);
        }
        final destino = resolverDestinoDaNotificacao(notificacao.type, notificacao.payload);
        if (destino != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino));
        }
      },
    );
  }

  String _tempoDecorrido(DateTime d) {
    final diferenca = DateTime.now().difference(d);
    if (diferenca.inMinutes < 1) return 'agora';
    if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
    if (diferenca.inHours < 24) return 'há ${diferenca.inHours}h';
    return 'há ${diferenca.inDays}d';
  }
}

class _CarregandoDiscreto extends StatelessWidget {
  const _CarregandoDiscreto();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _AvisoDiscreto extends StatelessWidget {
  final String texto;
  const _AvisoDiscreto(this.texto);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(texto, style: const TextStyle(color: DalehColors.muted)),
      ),
    );
  }
}

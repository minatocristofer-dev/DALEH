import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../../theme/daleh_theme.dart';
import 'challenges_providers.dart';
import 'criar_desafio_screen.dart';
import 'escolher_time_dialog.dart';
import 'models/challenge_request.dart';
import 'models/team_challenge.dart';

String _dataFormatada(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class DesafiosTab extends StatelessWidget {
  const DesafiosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CriarDesafioScreen())),
          backgroundColor: DalehColors.turf,
          foregroundColor: DalehColors.bg,
          icon: const Icon(Icons.add),
          label: const Text('Criar desafio'),
        ),
        body: Column(
          children: [
            Material(
              color: DalehColors.bg,
              child: const TabBar(tabs: [Tab(text: 'ABERTOS'), Tab(text: 'MEUS')]),
            ),
            const Expanded(child: TabBarView(children: [_DesafiosAbertos(), _MeusDesafios()])),
          ],
        ),
      ),
    );
  }
}

class _DesafiosAbertos extends ConsumerWidget {
  const _DesafiosAbertos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desafiosAsync = ref.watch(desafiosAbertosProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(desafiosAbertosProvider),
      child: desafiosAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(desafiosAbertosProvider))],
        ),
        data: (desafios) {
          if (desafios.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.emoji_events_outlined,
                  titulo: 'Nenhum desafio aberto',
                  subtitulo: 'Quando algum time criar um desafio, ele aparece aqui.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: desafios.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DesafioAbertoCard(desafio: desafios[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DesafioAbertoCard extends ConsumerStatefulWidget {
  final TeamChallenge desafio;
  const _DesafioAbertoCard({required this.desafio});

  @override
  ConsumerState<_DesafioAbertoCard> createState() => _DesafioAbertoCardState();
}

class _DesafioAbertoCardState extends ConsumerState<_DesafioAbertoCard> {
  bool _enviando = false;

  Future<void> _solicitar() async {
    final teamId = await escolherTimeDialog(context, ref, titulo: 'Solicitar com qual time?');
    if (teamId == null) return;
    setState(() => _enviando = true);
    try {
      await ref.read(challengesActionsProvider).solicitar(widget.desafio.id, requestingTeamId: teamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada!')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.desafio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CrestAvatar(url: d.teamCrestUrl, nome: d.teamName ?? '?', tamanho: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.teamName ?? 'Time', style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text('${d.city} · ${_dataFormatada(d.scheduledDate)} às ${d.scheduledTime}',
                          style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                StatusChip(texto: d.desiredLevel.toUpperCase(), cor: DalehColors.amber),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Solicitar', onPressed: _solicitar, carregando: _enviando),
          ],
        ),
      ),
    );
  }
}

class _MeusDesafios extends ConsumerWidget {
  const _MeusDesafios();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meusAsync = ref.watch(meusDesafiosProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(meusDesafiosProvider),
      child: meusAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meusDesafiosProvider))],
        ),
        data: (meus) {
          if (meus.comoOrganizador.isEmpty && meus.minhasSolicitacoes.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.emoji_events_outlined,
                  titulo: 'Você ainda não tem desafios',
                  subtitulo: 'Crie um desafio ou solicite um dos abertos.',
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              if (meus.comoOrganizador.isNotEmpty) ...[
                const Text('COMO ORGANIZADOR', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...meus.comoOrganizador.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DesafioOrganizadorCard(desafio: d),
                    )),
                const SizedBox(height: 16),
              ],
              if (meus.minhasSolicitacoes.isNotEmpty) ...[
                const Text('MINHAS SOLICITAÇÕES', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                ...meus.minhasSolicitacoes.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SolicitacaoCard(solicitacao: r),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DesafioOrganizadorCard extends ConsumerStatefulWidget {
  final TeamChallenge desafio;
  const _DesafioOrganizadorCard({required this.desafio});

  @override
  ConsumerState<_DesafioOrganizadorCard> createState() => _DesafioOrganizadorCardState();
}

class _DesafioOrganizadorCardState extends ConsumerState<_DesafioOrganizadorCard> {
  String? _aceitandoId;

  Future<void> _aceitar(ChallengeRequest solicitacao) async {
    setState(() => _aceitandoId = solicitacao.id);
    try {
      await ref.read(challengesActionsProvider).aceitar(widget.desafio.id, solicitacao.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Desafio confirmado! O jogo já foi criado.')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _aceitandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.desafio;
    final pendentes = d.requests.where((r) => r.pendente).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${d.city} · ${_dataFormatada(d.scheduledDate)} às ${d.scheduledTime}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ),
                StatusChip(texto: d.status, cor: d.aberta ? DalehColors.turf : DalehColors.muted),
              ],
            ),
            if (pendentes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Nenhuma solicitação pendente.', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
              )
            else
              ...pendentes.map((r) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        CrestAvatar(url: r.requestingTeamCrestUrl, nome: r.requestingTeamName ?? '?', tamanho: 32),
                        const SizedBox(width: 10),
                        Expanded(child: Text(r.requestingTeamName ?? 'Time')),
                        PrimaryButton(
                          label: 'Aceitar',
                          carregando: _aceitandoId == r.id,
                          onPressed: () => _aceitar(r),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _SolicitacaoCard extends StatelessWidget {
  final ChallengeRequest solicitacao;
  const _SolicitacaoCard({required this.solicitacao});

  @override
  Widget build(BuildContext context) {
    final r = solicitacao;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.challengeOrganizerTeamName ?? 'Time', style: const TextStyle(fontWeight: FontWeight.w900)),
                  if (r.challengeCity != null)
                    Text(
                      '${r.challengeCity} · ${r.challengeScheduledDate != null ? _dataFormatada(r.challengeScheduledDate!) : ''} às ${r.challengeScheduledTime ?? ''}',
                      style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                    ),
                ],
              ),
            ),
            StatusChip(
              texto: r.status,
              cor: r.status == 'ACEITA' ? DalehColors.turf : (r.status == 'RECUSADA' ? DalehColors.danger : DalehColors.amber),
            ),
          ],
        ),
      ),
    );
  }
}

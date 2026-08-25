import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../../theme/daleh_theme.dart';
import '../perfil/perfil_publico_screen.dart';
import '../teams/teams_providers.dart';
import 'matches_providers.dart';
import 'models/match.dart';
import 'models/match_attendance.dart';
import 'models/match_event.dart';

class JogoDetailScreen extends ConsumerWidget {
  final String matchId;
  const JogoDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidaAsync = ref.watch(partidaDetalheProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Jogo')),
      body: partidaAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(partidaDetalheProvider(matchId))),
        data: (partida) => _JogoDetailBody(partida: partida),
      ),
    );
  }
}

class _JogoDetailBody extends ConsumerStatefulWidget {
  final Match partida;
  const _JogoDetailBody({required this.partida});

  @override
  ConsumerState<_JogoDetailBody> createState() => _JogoDetailBodyState();
}

class _JogoDetailBodyState extends ConsumerState<_JogoDetailBody> {
  bool _carregandoPresenca = false;

  Future<void> _confirmar() async {
    setState(() => _carregandoPresenca = true);
    try {
      await ref.read(matchesActionsProvider).confirmarPresenca(widget.partida.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _carregandoPresenca = false);
    }
  }

  Future<void> _cancelar() async {
    setState(() => _carregandoPresenca = true);
    try {
      await ref.read(matchesActionsProvider).cancelarPresenca(widget.partida.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _carregandoPresenca = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partida = widget.partida;
    final meuUserId = ref.watch(meuUserIdProvider);
    MatchAttendance? minhaPresenca;
    for (final a in partida.attendance ?? const <MatchAttendance>[]) {
      if (a.userId == meuUserId) {
        minhaPresenca = a;
        break;
      }
    }
    final souCriador = meuUserId != null && partida.souCriador(meuUserId);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (partida.temTimes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(children: [
                        CrestAvatar(url: partida.homeTeamCrestUrl, nome: partida.homeTeamName ?? 'A', tamanho: 56),
                        const SizedBox(height: 6),
                        Text(partida.homeTeamName ?? 'Time A', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: partida.homeScore != null
                            ? Text(
                                '${partida.homeScore} × ${partida.awayScore}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: DalehColors.turf),
                              )
                            : const Text('x', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: DalehColors.muted)),
                      ),
                      Column(children: [
                        CrestAvatar(url: partida.awayTeamCrestUrl, nome: partida.awayTeamName ?? 'B', tamanho: 56),
                        const SizedBox(height: 6),
                        Text(partida.awayTeamName ?? 'Time B', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ],
                  )
                else
                  Center(
                    child: Text(
                      partida.modalidadeLabel ?? 'Partida',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ),
                const SizedBox(height: 16),
                _linha(Icons.calendar_today, _dataHora(partida.scheduledAt)),
                if (partida.venueName != null) _linha(Icons.place, partida.venueName!),
                const SizedBox(height: 8),
                Center(child: StatusChip(texto: partida.status.toUpperCase(), cor: DalehColors.turf)),
                const SizedBox(height: 16),
                if (minhaPresenca == null)
                  PrimaryButton(label: 'Confirmar presença', onPressed: _confirmar, carregando: _carregandoPresenca)
                else
                  Column(
                    children: [
                      StatusChip(
                        texto: minhaPresenca.confirmado ? 'VOCÊ ESTÁ CONFIRMADO' : 'VOCÊ ESTÁ NA LISTA DE ESPERA',
                        cor: minhaPresenca.confirmado ? DalehColors.turf : DalehColors.amber,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _carregandoPresenca ? null : _cancelar,
                        child: const Text('Cancelar minha presença'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const TabBar(tabs: [Tab(text: 'PARTICIPANTES'), Tab(text: 'SÚMULA')]),
          Expanded(
            child: TabBarView(
              children: [
                _ParticipantesTab(partida: partida),
                _SumulaTab(partida: partida, souCriador: souCriador),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: DalehColors.muted),
            const SizedBox(width: 6),
            Text(texto, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );

  String _dataHora(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year} às $hora:$min';
  }
}

// Ordem de exibição das linhas da escalação — grupo genérico o bastante pra
// cobrir as posições das 3 modalidades já cadastradas (Futsal, Society/Campo
// 7, Campo 11: ver prisma/seed.ts). Quem não tem posição cadastrada pra essa
// modalidade cai em "Sem posição definida" — nunca inventamos uma posição.
const _linhasDaEscalacao = ['Goleiro', 'Defesa', 'Meio', 'Ataque', 'Sem posição definida'];

String _linhaDaPosicao(String? posicao) {
  if (posicao == null) return 'Sem posição definida';
  final p = posicao.toLowerCase();
  if (p.contains('gol')) return 'Goleiro';
  if (p.contains('fixo') || p.contains('zagueiro') || p.contains('lateral') || p.contains('ala')) return 'Defesa';
  if (p.contains('volante') || p.contains('meia')) return 'Meio';
  if (p.contains('pivô') || p.contains('pivo') || p.contains('atacante')) return 'Ataque';
  return 'Sem posição definida';
}

class _EventoComPlacar {
  final MatchEvent evento;
  final String? placarNoMomento;
  const _EventoComPlacar({required this.evento, this.placarNoMomento});
}

class _ParticipantesTab extends StatelessWidget {
  final Match partida;
  const _ParticipantesTab({required this.partida});

  @override
  Widget build(BuildContext context) {
    final confirmados = partida.attendance?.where((a) => a.confirmado).toList() ?? [];
    final espera = partida.attendance?.where((a) => a.naEspera).toList() ?? [];

    if (confirmados.isEmpty && espera.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Ninguém confirmou presença ainda.', style: TextStyle(color: DalehColors.muted)),
        ),
      );
    }

    if (partida.temTimes) {
      return _EscalacaoPorTime(partida: partida, confirmados: confirmados, espera: espera);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (confirmados.isNotEmpty) ...[
          Text('CONFIRMADOS (${confirmados.length})', style: const TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...confirmados.map((a) => _linhaJogador(context, a.userId, a.userFullName, a.userAvatarUrl)),
        ],
        if (espera.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('LISTA DE ESPERA (${espera.length})', style: const TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...espera.map((a) => _linhaJogador(context, a.userId, a.userFullName, a.userAvatarUrl)),
        ],
      ],
    );
  }

  static Widget _linhaJogador(BuildContext context, String userId, String? nome, String? avatarUrl) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: userId)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CrestAvatar(url: avatarUrl, nome: nome ?? '?', tamanho: 36),
            const SizedBox(width: 12),
            Text(nome ?? 'Jogador', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Escalação (Fase visual) agrupada por linha (Goleiro/Defesa/Meio/Ataque),
/// versão intermediária sem coordenadas exatas de campo tático — usa
/// `MatchAttendance.teamId`/`posicaoPrincipal`, resolvidos pelo backend em
/// tempo real (ver MatchesService.comEscalacao).
class _EscalacaoPorTime extends StatelessWidget {
  final Match partida;
  final List<MatchAttendance> confirmados;
  final List<MatchAttendance> espera;
  const _EscalacaoPorTime({required this.partida, required this.confirmados, required this.espera});

  @override
  Widget build(BuildContext context) {
    final doTimeCasa = confirmados.where((a) => a.teamId == partida.homeTeamId).toList();
    final doTimeFora = confirmados.where((a) => a.teamId == partida.awayTeamId).toList();
    final semTime = confirmados.where((a) => a.teamId == null).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _blocoTime(context, partida.homeTeamName ?? 'Time A', partida.homeTeamCrestUrl, doTimeCasa),
        const SizedBox(height: 20),
        _blocoTime(context, partida.awayTeamName ?? 'Time B', partida.awayTeamCrestUrl, doTimeFora),
        if (semTime.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('OUTROS CONFIRMADOS', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...semTime.map((a) => _ParticipantesTab._linhaJogador(context, a.userId, a.userFullName, a.userAvatarUrl)),
        ],
        if (espera.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('LISTA DE ESPERA (${espera.length})', style: const TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...espera.map((a) => _ParticipantesTab._linhaJogador(context, a.userId, a.userFullName, a.userAvatarUrl)),
        ],
      ],
    );
  }

  Widget _blocoTime(BuildContext context, String nome, String? crestUrl, List<MatchAttendance> jogadores) {
    final porLinha = <String, List<MatchAttendance>>{for (final linha in _linhasDaEscalacao) linha: []};
    for (final j in jogadores) {
      porLinha[_linhaDaPosicao(j.posicaoPrincipal)]!.add(j);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DalehColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CrestAvatar(url: crestUrl, nome: nome, tamanho: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(nome, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
              Text('${jogadores.length}', style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
            ],
          ),
          if (jogadores.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Ninguém confirmado ainda.', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
            )
          else
            for (final linha in _linhasDaEscalacao)
              if (porLinha[linha]!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(linha.toUpperCase(), style: const TextStyle(color: DalehColors.turf, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: porLinha[linha]!.map((j) => _fichaJogador(context, j)).toList(),
                ),
              ],
        ],
      ),
    );
  }

  Widget _fichaJogador(BuildContext context, MatchAttendance a) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: a.userId))),
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            CrestAvatar(url: a.userAvatarUrl, nome: a.userFullName ?? '?', tamanho: 40),
            const SizedBox(height: 4),
            Text(
              a.userFullName ?? 'Jogador',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumulaTab extends ConsumerStatefulWidget {
  final Match partida;
  final bool souCriador;
  const _SumulaTab({required this.partida, required this.souCriador});

  @override
  ConsumerState<_SumulaTab> createState() => _SumulaTabState();
}

class _SumulaTabState extends ConsumerState<_SumulaTab> {
  bool _enviando = false;

  @override
  Widget build(BuildContext context) {
    final partida = widget.partida;

    // Súmula com placar por time só existe pra partida nascida de um
    // TeamChallenge aceito (tem os dois times vinculados) — ver Fase 8,
    // auditoria: não dá pra atribuir gol a um time numa pelada avulsa sem
    // time nenhum. Pra essas, mantém o registro de evento genérico (mais
    // antigo, só do criador) exatamente como já funcionava antes.
    return partida.temTimes ? _sumulaComTimes(context) : _sumulaAvulsa(context);
  }

  Widget _sumulaComTimes(BuildContext context) {
    final partida = widget.partida;
    final golsEAssistencias = (partida.events ?? []).where((e) => e.eventType == 'goal' || e.eventType == 'assist').toList();
    final mvp = partida.mvpEvento;
    final podeRegistrar = partida.souGestorDaSumula && !partida.partidaEncerrada;

    return Scaffold(
      floatingActionButton: podeRegistrar
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarRegistrarGol(context),
              backgroundColor: DalehColors.turf,
              foregroundColor: DalehColors.bg,
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Registrar gol'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (golsEAssistencias.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nenhum gol registrado ainda.', style: TextStyle(color: DalehColors.muted))),
            )
          else
            ..._timelineComPlacar(partida, golsEAssistencias).map(_linhaEvento),
          if (partida.status == 'finished') ...[
            const SizedBox(height: 20),
            const Divider(color: DalehColors.line),
            const SizedBox(height: 14),
            if (mvp != null)
              _cartaoMvp(mvp)
            else if (partida.souGestorDaSumula)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ELEJA O MVP DA PARTIDA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Escolher MVP',
                    icon: Icons.star_outline,
                    carregando: _enviando,
                    onPressed: () => _mostrarElegerMvp(context),
                  ),
                ],
              )
            else
              const Center(
                child: Text('O MVP ainda não foi eleito.', style: TextStyle(color: DalehColors.muted)),
              ),
          ],
          if (widget.souCriador && !partida.partidaEncerrada) ...[
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _enviando ? null : () => _confirmarFinalizacao(context),
              child: const Text('Finalizar partida'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sumulaAvulsa(BuildContext context) {
    final eventos = widget.partida.events ?? [];

    return Scaffold(
      floatingActionButton: widget.souCriador
          ? FloatingActionButton.small(
              onPressed: () => _mostrarAdicionarEvento(context),
              backgroundColor: DalehColors.turf,
              foregroundColor: DalehColors.bg,
              child: const Icon(Icons.add),
            )
          : null,
      body: eventos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum evento registrado ainda.', style: TextStyle(color: DalehColors.muted)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventos.length,
              itemBuilder: (context, i) {
                final e = eventos[i];
                return ListTile(
                  leading: const Icon(Icons.sports_soccer, color: DalehColors.turf),
                  title: Text(rotuloDoEvento(e.eventType)),
                  subtitle: e.minute != null ? Text("${e.minute}'") : null,
                );
              },
            ),
    );
  }

  // Gol e assistência são dois MatchEvent independentes — o backend não
  // guarda um vínculo entre os dois (ver relatório da Fase 8, seção de
  // limitações), então a lista mostra cada evento na sua própria linha, sem
  // tentar "casar" um gol com sua assistência. O placar ao lado de cada gol é
  // calculado aqui mesmo, em ordem cronológica real (MatchEvent.createdAt,
  // Fase 9) — não é um campo que o backend devolve pronto.
  List<_EventoComPlacar> _timelineComPlacar(Match partida, List<MatchEvent> eventos) {
    final ordenados = [...eventos]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    var homeScore = 0;
    var awayScore = 0;
    final resultado = <_EventoComPlacar>[];
    for (final e in ordenados) {
      String? placar;
      if (e.eventType == 'goal') {
        if (e.teamId == partida.homeTeamId) {
          homeScore++;
        } else if (e.teamId == partida.awayTeamId) {
          awayScore++;
        }
        placar = '$homeScore × $awayScore';
      }
      resultado.add(_EventoComPlacar(evento: e, placarNoMomento: placar));
    }
    return resultado.reversed.toList();
  }

  Widget _linhaEvento(_EventoComPlacar item) {
    final evento = item.evento;
    final ehGol = evento.eventType == 'goal';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(ehGol ? Icons.sports_soccer : Icons.adjust, size: 16, color: ehGol ? DalehColors.turf : DalehColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${evento.userFullName ?? 'Jogador'} ${ehGol ? 'marcou um gol' : 'deu uma assistência'}',
              style: TextStyle(
                fontWeight: ehGol ? FontWeight.w700 : FontWeight.w500,
                color: ehGol ? DalehColors.text : DalehColors.muted,
              ),
            ),
          ),
          if (item.placarNoMomento != null)
            Text(item.placarNoMomento!, style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cartaoMvp(MatchEvent mvp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DalehColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DalehColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: DalehColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text('MVP da partida: ${mvp.userFullName ?? 'Jogador'}', style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarRegistrarGol(BuildContext context) async {
    final confirmados = widget.partida.attendance?.where((a) => a.confirmado).toList() ?? [];
    if (confirmados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ninguém confirmado nessa partida ainda.')),
      );
      return;
    }

    String? goleadorId = confirmados.first.userId;
    String? assistenteId;
    var enviando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DalehColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Registrar gol', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: goleadorId,
                    decoration: const InputDecoration(labelText: 'Quem marcou?'),
                    items: confirmados
                        .map((a) => DropdownMenuItem(value: a.userId, child: Text(a.userFullName ?? a.userId)))
                        .toList(),
                    onChanged: (v) => setState(() => goleadorId = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    initialValue: assistenteId,
                    decoration: const InputDecoration(labelText: 'Assistência'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Sem assistência')),
                      ...confirmados.map((a) => DropdownMenuItem<String?>(value: a.userId, child: Text(a.userFullName ?? a.userId))),
                    ],
                    onChanged: (v) => setState(() => assistenteId = v),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Registrar',
                    carregando: enviando,
                    onPressed: () async {
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(matchesActionsProvider).registrarGol(
                              widget.partida.id,
                              scorerId: goleadorId!,
                              assistId: assistenteId,
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } on ApiException catch (e) {
                        setState(() {
                          erro = e.message;
                          enviando = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _mostrarElegerMvp(BuildContext context) async {
    final confirmados = widget.partida.attendance?.where((a) => a.confirmado).toList() ?? [];
    if (confirmados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ninguém confirmado nessa partida.')),
      );
      return;
    }

    String? mvpId = confirmados.first.userId;
    var enviando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DalehColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Eleger o MVP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: mvpId,
                    decoration: const InputDecoration(labelText: 'MVP da partida'),
                    items: confirmados
                        .map((a) => DropdownMenuItem(value: a.userId, child: Text(a.userFullName ?? a.userId)))
                        .toList(),
                    onChanged: (v) => setState(() => mvpId = v),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Eleger MVP',
                    carregando: enviando,
                    onPressed: () async {
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(matchesActionsProvider).elegerMvp(widget.partida.id, userId: mvpId!);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } on ApiException catch (e) {
                        setState(() {
                          erro = e.message;
                          enviando = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarFinalizacao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar partida?'),
        content: const Text('Depois de finalizada, não é mais possível registrar gols, assistências ou o MVP passa a poder ser eleito.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _enviando = true);
    try {
      await ref.read(matchesActionsProvider).atualizarStatus(widget.partida.id, 'finished');
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarAdicionarEvento(BuildContext context) async {
    final confirmados = widget.partida.attendance?.where((a) => a.confirmado).toList() ?? [];
    if (confirmados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ninguém confirmado nessa partida ainda.')),
      );
      return;
    }

    String? jogadorId = confirmados.first.userId;
    String tipo = 'goal';
    final minutoCtrl = TextEditingController();
    var enviando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DalehColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Registrar evento', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: jogadorId,
                    decoration: const InputDecoration(labelText: 'Jogador'),
                    items: confirmados
                        .map((a) => DropdownMenuItem(value: a.userId, child: Text(a.userFullName ?? a.userId)))
                        .toList(),
                    onChanged: (v) => setState(() => jogadorId = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo de evento'),
                    items: tiposDeEventoDeJogo
                        .map((t) => DropdownMenuItem(value: t, child: Text(rotuloDoEvento(t))))
                        .toList(),
                    onChanged: (v) => setState(() => tipo = v ?? tipo),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: minutoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minuto (opcional)'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Registrar',
                    carregando: enviando,
                    onPressed: () async {
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(matchesActionsProvider).registrarEvento(
                              widget.partida.id,
                              userId: jogadorId!,
                              eventType: tipo,
                              minute: int.tryParse(minutoCtrl.text.trim()),
                            );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } on ApiException catch (e) {
                        setState(() {
                          erro = e.message;
                          enviando = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

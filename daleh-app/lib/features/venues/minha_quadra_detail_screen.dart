import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/compartilhar_imagem.dart';
import '../../shared/widgets/booking_card.dart';
import '../../shared/widgets/daleh_wordmark.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/faixa_de_dias.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import '../perfil/perfil_publico_screen.dart';
import 'models/booking.dart';
import 'models/venue.dart';
import 'models/venue_blocked_date.dart';
import 'models/venue_slot.dart';
import 'venue_form_screen.dart';
import 'venues_providers.dart';

class MinhaQuadraDetailScreen extends ConsumerWidget {
  final String venueId;
  // 0=Painel, 1=Horários, 2=Reservas, 3=Bloqueios.
  final int abaInicial;
  const MinhaQuadraDetailScreen({super.key, required this.venueId, this.abaInicial = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quadraAsync = ref.watch(quadraDetalheProvider(venueId));

    return DefaultTabController(
      length: 4,
      initialIndex: abaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: Text(quadraAsync.maybeWhen(data: (v) => v.name, orElse: () => 'Minha quadra')),
          actions: [
            quadraAsync.maybeWhen(
              data: (quadra) => IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => VenueFormScreen(quadraParaEditar: quadra)),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [Tab(text: 'PAINEL'), Tab(text: 'HORÁRIOS'), Tab(text: 'RESERVAS'), Tab(text: 'BLOQUEIOS')],
          ),
        ),
        body: quadraAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(quadraDetalheProvider(venueId))),
          data: (quadra) => TabBarView(
            children: [
              _PainelBody(venueId: venueId),
              _HorariosBody(quadra: quadra),
              _ReservasRecebidasBody(venueId: venueId),
              _BloqueiosBody(venueId: venueId),
            ],
          ),
        ),
      ),
    );
  }
}

String _isoDoPainel(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// Painel do Locador (QA Round 3, item 1): calendário de 14 dias + agenda do
// dia (LIVRE/RESERVADO/FIXO/INDISPONÍVEL) reaproveitando o mesmo
// `disponibilidadeProvider` da tela de reserva do jogador — não existe
// fluxo paralelo — seguido do resumo numérico (ocupação, valores em
// reservas, time mais frequente) do Round 2.
class _PainelBody extends ConsumerStatefulWidget {
  final String venueId;
  const _PainelBody({required this.venueId});

  @override
  ConsumerState<_PainelBody> createState() => _PainelBodyState();
}

class _PainelBodyState extends ConsumerState<_PainelBody> {
  DateTime _data = DateTime.now();

  Future<void> _escolherData() async {
    final agora = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: agora.subtract(const Duration(days: 60)),
      lastDate: agora.add(const Duration(days: 365)),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _marcarComoFixo(VenueSlot slot) async {
    if (slot.bookingId == null) return;
    final nomeCtrl = TextEditingController(text: slot.fixedTeamName ?? '');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como horário fixo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${slot.startTime} – ${slot.endTime} vira um horário fixo: ninguém mais consegue reservar até você remover a marcação.'),
            const SizedBox(height: 14),
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Time/grupo (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Marcar como fixo')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(venuesActionsProvider).marcarComoFixo(
            widget.venueId,
            slot.bookingId!,
            isFixed: true,
            fixedTeamName: nomeCtrl.text.trim().isEmpty ? null : nomeCtrl.text.trim(),
            dataAgenda: _isoDoPainel(_data),
          );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removerHorarioFixo(VenueSlot slot) async {
    if (slot.bookingId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover horário fixo?'),
        content: Text('${slot.startTime} – ${slot.endTime} volta a ficar disponível pra reserva normal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover', style: TextStyle(color: DalehColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(venuesActionsProvider).marcarComoFixo(
            widget.venueId,
            slot.bookingId!,
            isFixed: false,
            dataAgenda: _isoDoPainel(_data),
          );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataIso = _isoDoPainel(_data);
    final dashboardAsync = ref.watch(venueDashboardProvider(widget.venueId));
    final agendaAsync = ref.watch(disponibilidadeProvider((venueId: widget.venueId, data: dataIso)));
    final bloqueiosAsync = ref.watch(bloqueiosDaQuadraProvider(widget.venueId));
    final diaBloqueado = bloqueiosAsync.maybeWhen(
      data: (bloqueios) => bloqueios.any(
        (b) => b.date.year == _data.year && b.date.month == _data.month && b.date.day == _data.day,
      ),
      orElse: () => false,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(venueDashboardProvider(widget.venueId));
        ref.invalidate(disponibilidadeProvider((venueId: widget.venueId, data: dataIso)));
        ref.invalidate(bloqueiosDaQuadraProvider(widget.venueId));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          FaixaDeDias(
            selecionado: _data,
            onSelecionar: (d) => setState(() => _data = d),
            onEscolherOutraData: _escolherData,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text('AGENDA DO DIA', style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6)),
          ),
          if (diaBloqueado)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.block, color: DalehColors.danger),
                  title: const Text('Quadra bloqueada neste dia', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Nenhum horário disponível — veja o motivo na aba Bloqueios.', style: TextStyle(color: DalehColors.muted)),
                ),
              ),
            )
          else
            agendaAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (erro, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ErrorState(
                  erro: erro,
                  onTentarNovamente: () => ref.invalidate(disponibilidadeProvider((venueId: widget.venueId, data: dataIso))),
                ),
              ),
              data: (slots) {
                if (slots.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: EmptyState(
                      icon: Icons.event_note_outlined,
                      titulo: 'Nenhum horário cadastrado',
                      subtitulo: 'Cadastre horários na aba Horários pra essa agenda aparecer aqui.',
                    ),
                  );
                }
                final ordenados = [...slots]..sort((a, b) => a.startTime.compareTo(b.startTime));
                return Column(
                  children: ordenados
                      .map(
                        (slot) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: _AgendaSlotTile(
                            slot: slot,
                            onMarcarFixo: () => _marcarComoFixo(slot),
                            onRemoverFixo: () => _removerHorarioFixo(slot),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('RESUMO DO MÊS', style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.6)),
          ),
          dashboardAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (erro, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(venueDashboardProvider(widget.venueId))),
            ),
            data: (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statCard('RESERVAS HOJE', '${d.reservasHoje}')),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('LIVRES HOJE', '${d.horariosDisponiveisHoje}')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _statCard('OCUPAÇÃO DO MÊS', '${d.indiceOcupacaoMes}%')),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('RESERVAS NO MÊS', '${d.reservasMes}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _linhaValor('Valor em reservas — hoje', d.valorEmReservasHoje),
                          const Divider(color: DalehColors.line, height: 24),
                          _linhaValor('Valor em reservas — mês', d.valorEmReservasMes),
                        ],
                      ),
                    ),
                  ),
                  if (d.timeMaisFrequente != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events_outlined, color: DalehColors.turf),
                        title: Text(d.timeMaisFrequente!.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text('Time/jogador mais frequente no mês', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
                        trailing: Text(
                          '${d.timeMaisFrequente!.reservas}x',
                          style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String valor) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(valor, style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: DalehColors.muted, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _linhaValor(String label, double valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: DalehColors.muted)),
        // Formatação simples (sem pacote de moeda novo) — "não adicionar
        // dependência externa desnecessária" (Priority 5, item 26).
        Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Um horário da agenda do Locador — estado visual (QA Round 3, item 1.1):
/// LIVRE (lima), RESERVADO (âmbar, com quem reservou), FIXO (azul, com
/// cadeado e nome do time/grupo). A ação de marcar/remover horário fixo só
/// aparece quando existe uma reserva de verdade por trás (`bookingId`) —
/// não dá pra fixar um horário sem reserva, o backend não tem o que marcar.
class _AgendaSlotTile extends StatelessWidget {
  final VenueSlot slot;
  final VoidCallback onMarcarFixo;
  final VoidCallback onRemoverFixo;
  const _AgendaSlotTile({required this.slot, required this.onMarcarFixo, required this.onRemoverFixo});

  @override
  Widget build(BuildContext context) {
    final fixo = slot.fixo;
    final reservado = !fixo && (slot.ocupado ?? false);

    final Color cor = fixo ? DalehColors.info : (reservado ? DalehColors.amber : DalehColors.turf);
    final IconData icone = fixo ? Icons.lock_outline : (reservado ? Icons.event_busy_outlined : Icons.event_available_outlined);
    final String rotulo = fixo ? 'FIXO' : (reservado ? 'RESERVADO' : 'LIVRE');
    final String? subtitulo = fixo ? (slot.fixedTeamName ?? 'Horário fixo') : (reservado ? (slot.reservadoPorNome ?? 'Reservado') : null);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Icon(icone, color: cor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${slot.startTime} — ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      Text(rotulo, style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.4)),
                    ],
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitulo, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (slot.bookingId != null)
              IconButton(
                tooltip: fixo ? 'Remover horário fixo' : 'Marcar como horário fixo',
                icon: Icon(fixo ? Icons.lock_open_outlined : Icons.lock_outline, color: fixo ? DalehColors.info : DalehColors.muted),
                onPressed: fixo ? onRemoverFixo : onMarcarFixo,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReservasRecebidasBody extends ConsumerStatefulWidget {
  final String venueId;
  const _ReservasRecebidasBody({required this.venueId});

  @override
  ConsumerState<_ReservasRecebidasBody> createState() => _ReservasRecebidasBodyState();
}

class _ReservasRecebidasBodyState extends ConsumerState<_ReservasRecebidasBody> {
  String? _emAcaoId;

  Future<void> _confirmar(Booking reserva) async {
    setState(() => _emAcaoId = reserva.id);
    try {
      await ref.read(venuesActionsProvider).confirmarReserva(widget.venueId, reserva.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _emAcaoId = null);
    }
  }

  Future<void> _recusar(Booking reserva) async {
    setState(() => _emAcaoId = reserva.id);
    try {
      await ref.read(venuesActionsProvider).recusarReserva(widget.venueId, reserva.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _emAcaoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservasAsync = ref.watch(reservasDaQuadraProvider(widget.venueId));
    final venueName = ref.watch(quadraDetalheProvider(widget.venueId)).maybeWhen(data: (v) => v.name, orElse: () => 'Quadra');

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reservasDaQuadraProvider(widget.venueId)),
      child: reservasAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [
            ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(reservasDaQuadraProvider(widget.venueId))),
          ],
        ),
        data: (reservas) {
          if (reservas.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icon: Icons.inbox_outlined,
                  titulo: 'Nenhuma reserva recebida ainda',
                  subtitulo: 'Quando alguém reservar essa quadra, aparece aqui.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, i) {
              final r = reservas[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReservaRecebidaCard(
                  reserva: r,
                  venueName: venueName,
                  emAcao: _emAcaoId == r.id,
                  onConfirmar: r.pendente ? () => _confirmar(r) : null,
                  onRecusar: r.pendente ? () => _recusar(r) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReservaRecebidaCard extends StatelessWidget {
  final Booking reserva;
  final String venueName;
  final bool emAcao;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRecusar;

  const _ReservaRecebidaCard({
    required this.reserva,
    required this.venueName,
    required this.emAcao,
    this.onConfirmar,
    this.onRecusar,
  });

  void _mostrarCompartilharConfronto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DalehColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: ConfrontoQuadraShareButton(reserva: reserva, venueName: venueName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: reserva.bookedById)),
                    ),
                    child: Text(
                      reserva.bookedByUserFullName ?? 'Jogador',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Compartilhar confronto',
                  icon: const Icon(Icons.share_outlined, color: DalehColors.muted, size: 20),
                  onPressed: () => _mostrarCompartilharConfronto(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BookingCard(reserva: reserva),
            if (onConfirmar != null || onRecusar != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (onRecusar != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: emAcao ? null : onRecusar,
                        child: const Text('Recusar'),
                      ),
                    ),
                  if (onRecusar != null && onConfirmar != null) const SizedBox(width: 10),
                  if (onConfirmar != null)
                    Expanded(
                      child: PrimaryButton(label: 'Confirmar', onPressed: onConfirmar, carregando: emAcao),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HorariosBody extends ConsumerWidget {
  final Venue quadra;
  const _HorariosBody({required this.quadra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = [...(quadra.slots ?? const <VenueSlot>[])]..sort((a, b) => a.weekday.compareTo(b.weekday));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarAdicionarHorario(context, ref),
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar horário'),
      ),
      body: slots.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icon: Icons.event_note_outlined,
                  titulo: 'Nenhum horário cadastrado',
                  subtitulo: 'Adicione os horários em que essa quadra fica disponível pra reserva.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: slots.length,
              separatorBuilder: (_, _) => const Divider(color: DalehColors.line),
              itemBuilder: (context, i) {
                final slot = slots[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: DalehColors.turf),
                  title: Text('${nomeDoDia(slot.weekday)} · ${slot.startTime} – ${slot.endTime}'),
                  subtitle: Text('R\$${slot.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: DalehColors.danger),
                    onPressed: () => _confirmarRemocao(context, ref, slot),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmarRemocao(BuildContext context, WidgetRef ref, VenueSlot slot) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover horário?'),
        content: Text('${nomeDoDia(slot.weekday)}, ${slot.startTime} – ${slot.endTime}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover', style: TextStyle(color: DalehColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(venuesActionsProvider).removerSlot(quadra.id, slot.id);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _mostrarAdicionarHorario(BuildContext context, WidgetRef ref) async {
    int weekday = 0;
    final inicioCtrl = TextEditingController();
    final fimCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
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
                  const Text('Adicionar horário', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: weekday,
                    decoration: const InputDecoration(labelText: 'Dia da semana'),
                    items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(nomeDoDia(i)))),
                    onChanged: (v) => setState(() => weekday = v ?? weekday),
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Início (ex: 18:00)')),
                  const SizedBox(height: 14),
                  TextField(controller: fimCtrl, decoration: const InputDecoration(labelText: 'Fim (ex: 19:00)')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: precoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Adicionar',
                    carregando: enviando,
                    onPressed: () async {
                      final preco = double.tryParse(precoCtrl.text.trim().replaceAll(',', '.'));
                      if (inicioCtrl.text.trim().isEmpty || fimCtrl.text.trim().isEmpty || preco == null) {
                        setState(() => erro = 'Preencha início, fim e preço corretamente.');
                        return;
                      }
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(venuesActionsProvider).criarSlot(
                              quadra.id,
                              weekday: weekday,
                              startTime: inicioCtrl.text.trim(),
                              endTime: fimCtrl.text.trim(),
                              price: preco,
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

String _dataCurta(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year}';
}

/// Datas em que o dono tirou a quadra inteira de disponibilidade (feriado,
/// manutenção) — só quem gerencia a quadra vê e mexe nessa aba; o jogador só
/// enxerga o resultado (nenhum horário disponível naquele dia).
class _BloqueiosBody extends ConsumerWidget {
  final String venueId;
  const _BloqueiosBody({required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloqueiosAsync = ref.watch(bloqueiosDaQuadraProvider(venueId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarBloquearData(context, ref),
        backgroundColor: DalehColors.turf,
        foregroundColor: DalehColors.bg,
        icon: const Icon(Icons.event_busy_outlined),
        label: const Text('Bloquear data'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bloqueiosDaQuadraProvider(venueId)),
        child: bloqueiosAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(bloqueiosDaQuadraProvider(venueId)))],
          ),
          data: (bloqueios) {
            if (bloqueios.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 40),
                  EmptyState(
                    icon: Icons.event_available_outlined,
                    titulo: 'Nenhuma data bloqueada',
                    subtitulo: 'Bloqueie um feriado ou um dia de manutenção pra tirar a quadra da disponibilidade.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: bloqueios.length,
              separatorBuilder: (_, _) => const Divider(color: DalehColors.line),
              itemBuilder: (context, i) {
                final b = bloqueios[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_busy, color: DalehColors.danger),
                  title: Text(_dataCurta(b.date)),
                  subtitle: b.reason != null && b.reason!.isNotEmpty ? Text(b.reason!) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: DalehColors.danger),
                    onPressed: () => _confirmarDesbloqueio(context, ref, b),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmarDesbloqueio(BuildContext context, WidgetRef ref, VenueBlockedDate bloqueio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloquear data?'),
        content: Text('A quadra volta a ficar disponível em ${_dataCurta(bloqueio.date)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desbloquear', style: TextStyle(color: DalehColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(venuesActionsProvider).desbloquearData(venueId, bloqueio.id);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _mostrarBloquearData(BuildContext context, WidgetRef ref) async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365 * 2)),
    );
    if (data == null || !context.mounted) return;

    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bloquear ${_dataCurta(data)}'),
        content: TextField(
          controller: motivoCtrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Bloquear')),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    try {
      final dataIso = '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      await ref.read(venuesActionsProvider).bloquearData(venueId, data: dataIso, motivo: motivoCtrl.text.trim());
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

/// Card de compartilhamento do confronto da quadra (QA Round 3, item 5) —
/// só com dado real da própria reserva: quem reservou (ou o nome do
/// time/grupo, se for um horário fixo), nome da quadra, data e horário.
/// Não existe vínculo no schema entre `Booking` e `Match` (confronto de dois
/// times com escudo) — inventar essa ligação por coincidência de
/// data/horário seria arriscar mostrar o confronto errado, então o card usa
/// só o que a própria reserva garante ser verdade.
class ConfrontoQuadraShareCard extends StatelessWidget {
  final Booking reserva;
  final String venueName;
  const ConfrontoQuadraShareCard({super.key, required this.reserva, required this.venueName});

  @override
  Widget build(BuildContext context) {
    final nome = reserva.isFixed ? (reserva.fixedTeamName ?? 'Horário fixo') : (reserva.bookedByUserFullName ?? 'Jogador');
    final hoje = DateTime.now();
    final data = reserva.date;
    final ehHoje = data.year == hoje.year && data.month == hoje.month && data.day == hoje.day;
    final horario = reserva.venueSlotStartTime != null && reserva.venueSlotEndTime != null
        ? '${reserva.venueSlotStartTime} – ${reserva.venueSlotEndTime}'
        : null;
    final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DalehRadius.lg),
        border: Border.all(color: DalehColors.turf),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14231C), Color(0xFF0A1512)],
        ),
      ),
      child: Column(
        children: [
          const DalehWordmark(),
          const SizedBox(height: 14),
          Text(
            ehHoje && reserva.venueSlotStartTime != null ? 'HOJE ÀS ${reserva.venueSlotStartTime}' : dataFormatada,
            style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          const SizedBox(height: 14),
          Text(venueName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            horario != null ? '$dataFormatada • $horario' : dataFormatada,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DalehColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// `ConfrontoQuadraShareCard` + botão "COMPARTILHAR CONFRONTO", mesmo padrão
/// do Player Card e da Súmula.
class ConfrontoQuadraShareButton extends StatefulWidget {
  final Booking reserva;
  final String venueName;
  const ConfrontoQuadraShareButton({super.key, required this.reserva, required this.venueName});

  @override
  State<ConfrontoQuadraShareButton> createState() => _ConfrontoQuadraShareButtonState();
}

class _ConfrontoQuadraShareButtonState extends State<ConfrontoQuadraShareButton> {
  final _cardKey = GlobalKey();
  bool _compartilhando = false;

  Future<void> _compartilhar() async {
    setState(() => _compartilhando = true);
    final sucesso = await compartilharImagem(_cardKey, texto: 'Reserva em ${widget.venueName}, pelo DALEH.', prefixoArquivo: 'daleh_confronto');
    if (mounted) {
      setState(() => _compartilhando = false);
      if (!sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar agora. Tenta de novo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(key: _cardKey, child: ConfrontoQuadraShareCard(reserva: widget.reserva, venueName: widget.venueName)),
        const SizedBox(height: 14),
        PrimaryButton(label: 'COMPARTILHAR CONFRONTO', icon: Icons.share_outlined, carregando: _compartilhando, onPressed: _compartilhar),
      ],
    );
  }
}

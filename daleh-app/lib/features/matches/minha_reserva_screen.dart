import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../theme/daleh_theme.dart';
import '../teams/teams_providers.dart';
import 'controle_pagamentos_tab.dart';
import 'jogo_detail_screen.dart';
import 'matches_providers.dart';
import 'models/match.dart';
import 'models/match_attendance.dart';

const _diasSemana = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
const _meses = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

String _dataCurta(DateTime d) {
  final l = d.toLocal();
  return '${_diasSemana[l.weekday % 7]} ${l.day} ${_meses[l.month - 1]}';
}

String _hora(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _rotuloStatus(String status) {
  switch (status) {
    case 'scheduled':
      return 'RESERVA CONFIRMADA';
    case 'in_progress':
      return 'EM ANDAMENTO';
    case 'finished':
      return 'FINALIZADA';
    case 'cancelled':
      return 'CANCELADA';
    default:
      return status.toUpperCase();
  }
}

/// Tela "Minha Reserva": resumo da quadra/partida, valor e controle de pagamento.
/// Os dados vêm da API de partida; nada aqui é inventado (sem foto de quadra,
/// sem duração, sem cidade — o cadastro da quadra não tem esses campos).
class MinhaReservaScreen extends ConsumerWidget {
  final String matchId;
  const MinhaReservaScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(partidaDetalheProvider(matchId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Reserva'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'detalhes') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => JogoDetailScreen(matchId: matchId)));
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'detalhes', child: Text('Ver detalhes da partida'))],
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(partidaDetalheProvider(matchId))),
        data: (partida) => _Corpo(partida: partida),
      ),
    );
  }
}

class _Corpo extends ConsumerStatefulWidget {
  final Match partida;
  const _Corpo({required this.partida});

  @override
  ConsumerState<_Corpo> createState() => _CorpoState();
}

class _CorpoState extends ConsumerState<_Corpo> {
  final Set<String> _salvando = {};
  bool _cancelando = false;

  Future<void> _alternar(MatchAttendance a) async {
    setState(() => _salvando.add(a.userId));
    final erro = await ref.read(matchesActionsProvider).marcarPagamento(widget.partida.id, a.userId, pago: !a.pago);
    if (!mounted) return;
    setState(() => _salvando.remove(a.userId));
    if (erro != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
  }

  Future<void> _compartilhar() async {
    final p = widget.partida;
    final valor = p.valorQuadra == null ? '' : '\nValor total: ${valorBrl(p.valorQuadra!)}';
    final texto = 'Partida DALEH${p.venueName != null ? ' em ${p.venueName}' : ''}\n'
        '${_dataCurta(p.scheduledAt)} · ${_hora(p.scheduledAt)}$valor';
    await Share.share(texto);
  }

  Future<void> _cancelarPresenca() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar presença?'),
        content: const Text('Você sai da lista de confirmados desta partida.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Voltar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Cancelar presença', style: TextStyle(color: DalehColors.danger))),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() => _cancelando = true);
    try {
      await ref.read(matchesActionsProvider).cancelarPresenca(widget.partida.id);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partida;
    final meuUserId = ref.watch(meuUserIdProvider);
    final confirmados = (p.attendance ?? const <MatchAttendance>[]).where((a) => a.confirmado).toList();
    final pagos = confirmados.where((a) => a.pago).length;
    final euConfirmado = meuUserId != null && confirmados.any((a) => a.userId == meuUserId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Hero(partida: p),
        const SizedBox(height: 12),
        _CartaoData(partida: p),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CartaoInfo(
                titulo: 'QUADRA COBERTA',
                valor: p.venueCovered == null ? 'Não informado' : (p.venueCovered! ? 'Sim' : 'Não'),
                destaque: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _CartaoValor(partida: p)),
          ],
        ),
        const SizedBox(height: 12),
        _CartaoPagamentos(
          confirmados: confirmados,
          pagos: pagos,
          gestor: p.souGestorDaSumula,
          salvando: _salvando,
          onAlternar: _alternar,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _compartilhar,
          icon: const Icon(Icons.share),
          label: const Text('COMPARTILHAR RESERVA'),
        ),
        if (euConfirmado) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cancelando ? null : _cancelarPresenca,
            icon: const Icon(Icons.event_busy),
            label: const Text('CANCELAR PRESENÇA'),
            style: OutlinedButton.styleFrom(foregroundColor: DalehColors.danger),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final Match partida;
  const _Hero({required this.partida});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('DALEH', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(DalehRadius.pill)),
                child: Text(_rotuloStatus(partida.status),
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Spacer(),
          Text(partida.venueName ?? 'Quadra a definir',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.sports_soccer, size: 16, color: DalehColors.textSecondary),
              const SizedBox(width: 6),
              Text(partida.modalidadeLabel ?? 'Partida', style: const TextStyle(color: DalehColors.textSecondary)),
              if (partida.venueAddress != null && partida.venueAddress!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.place_outlined, size: 16, color: DalehColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(partida.venueAddress!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: DalehColors.textSecondary)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CartaoData extends StatelessWidget {
  final Match partida;
  const _CartaoData({required this.partida});

  @override
  Widget build(BuildContext context) {
    return _Cartao(
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: DalehColors.turf, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DATA E HORÁRIO', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${_dataCurta(partida.scheduledAt)} • ${_hora(partida.scheduledAt)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: DalehColors.turf)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoInfo extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool destaque;
  const _CartaoInfo({required this.titulo, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: destaque ? DalehColors.turf : DalehColors.text,
              )),
        ],
      ),
    );
  }
}

class _CartaoValor extends StatelessWidget {
  final Match partida;
  const _CartaoValor({required this.partida});

  @override
  Widget build(BuildContext context) {
    final valor = partida.valorQuadra;
    final r = partida.resumoPagamento;
    String? subtitulo;
    if (valor == null) {
      subtitulo = 'Aguardando o organizador';
    } else if (r?.valorPorJogadorAvulsa != null) {
      subtitulo = '${valorBrl(r!.valorPorJogadorAvulsa!)} por jogador';
    } else if (r?.home?.valorPorJogador != null && r?.away?.valorPorJogador != null) {
      subtitulo = r!.home!.valorPorJogador == r.away!.valorPorJogador
          ? '${valorBrl(r.home!.valorPorJogador!)} por jogador'
          : 'Por jogador: ${valorBrl(r.home!.valorPorJogador!)} / ${valorBrl(r.away!.valorPorJogador!)}';
    }

    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('VALOR TOTAL', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(valor == null ? 'Não informado' : valorBrl(valor),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: valor == null ? DalehColors.muted : DalehColors.turf,
              )),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(subtitulo, style: const TextStyle(color: DalehColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _CartaoPagamentos extends StatelessWidget {
  final List<MatchAttendance> confirmados;
  final int pagos;
  final bool gestor;
  final Set<String> salvando;
  final void Function(MatchAttendance) onAlternar;
  const _CartaoPagamentos({
    required this.confirmados,
    required this.pagos,
    required this.gestor,
    required this.salvando,
    required this.onAlternar,
  });

  @override
  Widget build(BuildContext context) {
    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: DalehColors.turf, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Controle de pagamento', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('Capitão acompanha quem já pagou a quadra',
                        style: TextStyle(color: DalehColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$pagos/${confirmados.length}',
                      style: const TextStyle(color: DalehColors.turf, fontSize: 22, fontWeight: FontWeight.w900)),
                  const Text('pagaram', style: TextStyle(color: DalehColors.muted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (confirmados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Nenhum jogador confirmado ainda.', style: TextStyle(color: DalehColors.muted))),
            )
          else
            for (final a in confirmados)
              LinhaPagamento(
                attendance: a,
                salvando: salvando.contains(a.userId),
                podeAlterar: gestor,
                mostrarStatus: false,
                onTap: () => onAlternar(a),
              ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legenda(cor: Color(0xFF2ECC71), texto: 'Pago'),
              SizedBox(width: 16),
              _Legenda(cor: DalehColors.danger, texto: 'Pendente'),
            ],
          ),
          if (!gestor)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Só o organizador da partida pode marcar pagamentos.',
                  style: TextStyle(color: DalehColors.muted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Legenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 1.5)),
          child: Text('\$', style: TextStyle(color: cor, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  final Widget child;
  const _Cartao({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(DalehRadius.lg),
        border: Border.all(color: DalehColors.line),
      ),
      child: child,
    );
  }
}

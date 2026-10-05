import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../theme/daleh_theme.dart';
import 'matches_providers.dart';
import 'models/match.dart';
import 'models/match_attendance.dart';

const corPago = Color(0xFF2ECC71);
const corPendente = DalehColors.danger;

String valorBrl(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

/// Controle de pagamento da quadra: o gestor informa o valor total, o backend
/// divide 50/50 entre os times e, dentro de cada time, igual entre os jogadores.
/// Só o gestor da partida altera; os demais apenas visualizam.
class ControlePagamentosTab extends ConsumerStatefulWidget {
  final Match partida;
  const ControlePagamentosTab({super.key, required this.partida});

  @override
  ConsumerState<ControlePagamentosTab> createState() => _ControlePagamentosTabState();
}

class _ControlePagamentosTabState extends ConsumerState<ControlePagamentosTab> {
  final Set<String> _salvando = {};

  Future<void> _alternar(MatchAttendance a) async {
    setState(() => _salvando.add(a.userId));
    final erro = await ref
        .read(matchesActionsProvider)
        .marcarPagamento(widget.partida.id, a.userId, pago: !a.pago);
    if (!mounted) return;
    setState(() => _salvando.remove(a.userId));
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  Future<void> _informarValor() async {
    final atual = widget.partida.valorQuadra;
    final controlador = TextEditingController(text: atual == null ? '' : atual.toStringAsFixed(2).replaceAll('.', ','));

    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valor total da quadra'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor (R\$)', helperText: 'Metade vai pra cada time; cada time divide entre os seus jogadores.'),
        ),
        actions: [
          if (atual != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: const Text('Remover valor', style: TextStyle(color: DalehColors.danger)),
            ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(controlador.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (texto == null) return;

    double? novo;
    if (texto.trim().isNotEmpty) {
      novo = double.tryParse(texto.trim().replaceAll(',', '.'));
      if (novo == null || novo <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite um valor maior que zero.')));
        }
        return;
      }
    }

    final erro = await ref.read(matchesActionsProvider).definirValorQuadra(widget.partida.id, valor: novo);
    if (mounted && erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final partida = widget.partida;
    final confirmados = (partida.attendance ?? const <MatchAttendance>[]).where((a) => a.confirmado).toList();
    final pagos = confirmados.where((a) => a.pago).length;
    final gestor = partida.souGestorDaSumula;

    if (confirmados.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhum jogador confirmado ainda.', style: TextStyle(color: DalehColors.muted)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Resumo(
          partida: partida,
          pagos: pagos,
          confirmados: confirmados.length,
          gestor: gestor,
          onInformarValor: _informarValor,
        ),
        const SizedBox(height: 12),
        for (final a in confirmados)
          LinhaPagamento(
            attendance: a,
            salvando: _salvando.contains(a.userId),
            podeAlterar: gestor,
            onTap: () => _alternar(a),
          ),
        if (!gestor)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Só o organizador da partida pode marcar pagamentos.',
                style: TextStyle(color: DalehColors.muted, fontSize: 12)),
          ),
      ],
    );
  }
}

class _Resumo extends StatelessWidget {
  final Match partida;
  final int pagos;
  final int confirmados;
  final bool gestor;
  final VoidCallback onInformarValor;

  const _Resumo({
    required this.partida,
    required this.pagos,
    required this.confirmados,
    required this.gestor,
    required this.onInformarValor,
  });

  @override
  Widget build(BuildContext context) {
    final valor = partida.valorQuadra;
    final resumo = partida.resumoPagamento;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(DalehRadius.lg),
        border: Border.all(color: DalehColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('CONTROLE DE PAGAMENTOS',
                    style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
              Text('$pagos/$confirmados pagaram',
                  style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          if (valor == null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    gestor ? 'Informe o valor total da quadra para dividir o pagamento.' : 'O valor da quadra ainda não foi informado.',
                    style: const TextStyle(color: DalehColors.muted),
                  ),
                ),
                if (gestor) TextButton(onPressed: onInformarValor, child: const Text('Informar valor')),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(child: Text('Quadra ${valorBrl(valor)}', style: const TextStyle(fontWeight: FontWeight.w900))),
                if (gestor)
                  IconButton(onPressed: onInformarValor, icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Alterar valor'),
              ],
            ),
            if (resumo != null) ...[
              const SizedBox(height: 4),
              Text('Recebido ${valorBrl(resumo.totalRecebido ?? 0)} de ${valorBrl(valor)}',
                  style: const TextStyle(color: DalehColors.textSecondary)),
              if (resumo.home != null && resumo.away != null) ...[
                const SizedBox(height: 8),
                _LinhaTime(nome: partida.homeTeamName ?? 'Time A', total: resumo.home!),
                _LinhaTime(nome: partida.awayTeamName ?? 'Time B', total: resumo.away!),
              ] else if (resumo.valorPorJogadorAvulsa != null) ...[
                const SizedBox(height: 4),
                Text('${valorBrl(resumo.valorPorJogadorAvulsa!)} por jogador',
                    style: const TextStyle(color: DalehColors.textSecondary)),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _LinhaTime extends StatelessWidget {
  final String nome;
  final TotalTimePagamento total;
  const _LinhaTime({required this.nome, required this.total});

  @override
  Widget build(BuildContext context) {
    final porJogador = total.valorPorJogador;
    final texto = porJogador == null
        ? '${valorBrl(total.valorTime)} · sem jogadores confirmados'
        : '${valorBrl(total.valorTime)} · ${valorBrl(porJogador)} por jogador (${total.jogadores})';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('$nome: $texto', style: const TextStyle(fontSize: 13)),
    );
  }
}

class LinhaPagamento extends StatelessWidget {
  final MatchAttendance attendance;
  final bool salvando;
  final bool podeAlterar;
  final VoidCallback onTap;
  final bool mostrarStatus;

  const LinhaPagamento({
    super.key,
    required this.attendance,
    required this.salvando,
    required this.podeAlterar,
    required this.onTap,
    this.mostrarStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final pago = attendance.pago;
    final cor = pago ? corPago : corPendente;
    final devido = attendance.valorDevido;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(DalehRadius.md),
        border: Border.all(color: DalehColors.line),
      ),
      child: Row(
        children: [
          CrestAvatar(url: attendance.userAvatarUrl, nome: attendance.userFullName ?? '?', tamanho: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendance.userFullName ?? 'Jogador',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if (mostrarStatus)
                  Text(pago ? 'Pago' : 'Pendente', style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (devido != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(valorBrl(devido), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          if (salvando)
            const SizedBox(width: 36, height: 36, child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Semantics(
              button: podeAlterar,
              label: pago ? 'Pago' : 'Pendente',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: podeAlterar ? onTap : null,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cor.withValues(alpha: 0.15),
                    border: Border.all(color: cor, width: 1.5),
                  ),
                  child: Text('\$', style: TextStyle(color: cor, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

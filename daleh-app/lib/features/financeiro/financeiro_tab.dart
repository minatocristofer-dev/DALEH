import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../theme/daleh_theme.dart';
import 'financeiro_providers.dart';
import 'models/financeiro.dart';

String _valor(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

String _data(DateTime d) {
  final local = d.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

class FinanceiroTab extends ConsumerWidget {
  final String teamId;
  const FinanceiroTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cobrancasDoTimeProvider(teamId));
    return async.when(
      loading: () => const LoadingState(),
      error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(cobrancasDoTimeProvider(teamId))),
      data: (dados) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(cobrancasDoTimeProvider(teamId)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SecaoPix(teamId: teamId, dados: dados),
            const SizedBox(height: 16),
            if (dados.souGestor) _BotaoNovaCobranca(teamId: teamId),
            if (dados.souGestor) const SizedBox(height: 12),
            if (dados.cobrancas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Nenhuma cobrança ainda.', style: TextStyle(color: DalehColors.muted))),
              )
            else
              for (final c in dados.cobrancas)
                dados.souGestor
                    ? _CartaoCobrancaGestor(teamId: teamId, cobranca: c)
                    : _CartaoCobrancaJogador(cobranca: c),
          ],
        ),
      ),
    );
  }
}

class _SecaoPix extends ConsumerWidget {
  final String teamId;
  final CobrancasDoTime dados;
  const _SecaoPix({required this.teamId, required this.dados});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chave = dados.pixKey;
    final temChave = chave != null && chave.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        border: Border.all(color: DalehColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CHAVE PIX DO TIME', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: DalehColors.turf)),
          const SizedBox(height: 8),
          if (!temChave)
            Text(
              dados.souGestor ? 'Você ainda não cadastrou a chave PIX do time.' : 'O capitão ainda não cadastrou a chave PIX.',
              style: const TextStyle(color: DalehColors.muted),
            )
          else ...[
            if (dados.pixNome != null && dados.pixNome!.isNotEmpty)
              Text(dados.pixNome!, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            SelectableText(chave, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: chave));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave PIX copiada.')));
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar chave'),
              ),
            ),
          ],
          if (dados.souGestor)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _editarPix(context, ref),
                child: Text(temChave ? 'Alterar chave' : 'Cadastrar chave'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editarPix(BuildContext context, WidgetRef ref) async {
    final chaveCtrl = TextEditingController(text: dados.pixKey ?? '');
    final nomeCtrl = TextEditingController(text: dados.pixNome ?? '');

    final salvo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chave PIX do time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: chaveCtrl,
              decoration: const InputDecoration(labelText: 'Chave PIX (CPF, e-mail, telefone ou aleatória)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome do titular'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
        ],
      ),
    );

    if (salvo != true) return;
    final texto = chaveCtrl.text.trim();
    final titular = nomeCtrl.text.trim();
    if (texto.isEmpty || titular.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha a chave e o nome do titular.')));
      }
      return;
    }

    final erro = await ref.read(financeiroActionsProvider).definirPix(teamId, pixKey: texto, pixNome: titular);
    if (context.mounted && erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    }
  }
}

class _BotaoNovaCobranca extends ConsumerWidget {
  final String teamId;
  const _BotaoNovaCobranca({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => _novaCobranca(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Nova cobrança'),
    );
  }

  Future<void> _novaCobranca(BuildContext context, WidgetRef ref) async {
    final tituloCtrl = TextEditingController();
    final valorCtrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova cobrança'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Descrição (ex: Pelada de sábado)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor por jogador (R\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Criar')),
        ],
      ),
    );
    if (confirmado != true) return;

    final titulo = tituloCtrl.text.trim();
    final valor = double.tryParse(valorCtrl.text.trim().replaceAll(',', '.'));
    if (titulo.isEmpty || valor == null || valor <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a descrição e um valor maior que zero.')));
      }
      return;
    }

    final erro = await ref.read(financeiroActionsProvider).criarCobranca(teamId, titulo: titulo, valor: valor);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro ?? 'Cobrança criada para o time.')));
    }
  }
}

class _CartaoCobrancaGestor extends ConsumerWidget {
  final String teamId;
  final Cobranca cobranca;
  const _CartaoCobrancaGestor({required this.teamId, required this.cobranca});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = cobranca.itens.length;
    final pagos = cobranca.quantidadePagos;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(cobranca.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_valor(cobranca.valor)} · $pagos de $total pagaram · ${_data(cobranca.criadoEm)}'),
        children: [
          for (final item in cobranca.itens)
            SwitchListTile(
              title: Text(item.fullName),
              subtitle: Text(
                item.pago && item.pagoEm != null ? 'Pago em ${_data(item.pagoEm!)}' : 'Pendente',
                style: TextStyle(color: item.pago ? DalehColors.turf : DalehColors.muted),
              ),
              value: item.pago,
              onChanged: (novo) async {
                final erro = await ref
                    .read(financeiroActionsProvider)
                    .marcarPagamento(teamId, cobranca.id, item.userId, pago: novo);
                if (context.mounted && erro != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
                }
              },
            ),
        ],
      ),
    );
  }
}

class _CartaoCobrancaJogador extends StatelessWidget {
  final Cobranca cobranca;
  const _CartaoCobrancaJogador({required this.cobranca});

  @override
  Widget build(BuildContext context) {
    final minha = cobranca.itens.isEmpty ? null : cobranca.itens.first;
    final pago = minha?.pago ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(cobranca.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_valor(cobranca.valor)} · ${_data(cobranca.criadoEm)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pago ? DalehColors.turfDim : DalehColors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            pago ? 'PAGO' : 'PENDENTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: pago ? DalehColors.turf : DalehColors.amber,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/daleh_theme.dart';
import 'auth_controller.dart';

const _estados = ['RS', 'SP', 'RJ', 'MG', 'PR', 'SC', 'BA'];

const _modalidades = [
  {'key': 'futsal', 'label': 'Futsal', 'posicoes': ['Goleiro', 'Fixo', 'Ala', 'Pivô']},
  {'key': 'society', 'label': 'Society/Campo 7', 'posicoes': ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante']},
  {'key': 'campo11', 'label': 'Campo 11', 'posicoes': ['Goleiro', 'Zagueiro', 'Lateral', 'Volante', 'Meia', 'Atacante']},
];

List<String> _posicoesPara(Set<String> chaves) {
  final selecionadas = _modalidades.where((m) => chaves.contains(m['key']));
  final base = selecionadas.isNotEmpty ? selecionadas : _modalidades;
  final unicas = <String>[];
  for (final m in base) {
    for (final p in (m['posicoes'] as List<String>)) {
      if (!unicas.contains(p)) unicas.add(p);
    }
  }
  return unicas;
}

class CadastroScreen extends ConsumerStatefulWidget {
  final VoidCallback onIrParaLogin;
  const CadastroScreen({super.key, required this.onIrParaLogin});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  int step = 1;
  String? erro;

  final nomeCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();
  final telefoneCtrl = TextEditingController();
  final cidadeCtrl = TextEditingController();
  String estado = 'RS';

  Set<String> modalidadesSelecionadas = {'campo11'};
  String posicao = 'Atacante';
  String posicaoSec = 'Meia';
  String pe = 'Direito';
  bool consentimento = false;

  void _ajustarPosicoes() {
    final disponiveis = _posicoesPara(modalidadesSelecionadas);
    if (!disponiveis.contains(posicao)) posicao = disponiveis.first;
    if (!disponiveis.contains(posicaoSec)) {
      posicaoSec = disponiveis.length > 1 ? disponiveis[1] : disponiveis.first;
    }
  }

  Future<void> _concluir() async {
    if (!consentimento) {
      setState(() => erro = 'Você precisa aceitar o consentimento de dados sensíveis pra continuar.');
      return;
    }
    setState(() => erro = null);

    final dto = {
      'fullName': nomeCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'password': senhaCtrl.text,
      if (telefoneCtrl.text.trim().isNotEmpty) 'phone': telefoneCtrl.text.trim(),
      if (cidadeCtrl.text.trim().isNotEmpty) 'city': cidadeCtrl.text.trim(),
      'state': estado,
      'dominantFoot': pe,
      'modalidades': modalidadesSelecionadas
          .map((k) => {
                'modalidade': k.toUpperCase(),
                'posicaoPrincipal': posicao,
                'posicaoSecundaria': posicaoSec,
              })
          .toList(),
      'consentimentoDadosSensiveis': consentimento,
    };

    final erroApi = await ref.read(authControllerProvider.notifier).registrar(dto);
    if (erroApi != null) setState(() => erro = erroApi);
  }

  @override
  Widget build(BuildContext context) {
    final carregando = ref.watch(authControllerProvider).carregando;
    final posicoesDisponiveis = _posicoesPara(modalidadesSelecionadas);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: List.generate(3, (i) {
                  final n = i + 1;
                  final ativo = n == step;
                  final feito = n < step;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ativo ? DalehColors.turf : DalehColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: feito ? DalehColors.turfDim : DalehColors.line),
                    ),
                    child: feito
                        ? const Icon(Icons.check, size: 14, color: DalehColors.turf)
                        : Text('$n', style: TextStyle(fontWeight: FontWeight.w900, color: ativo ? DalehColors.bg : DalehColors.muted)),
                  );
                })),
                Text('Passo $step/3', style: const TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            if (step == 1) _passo1(),
            if (step == 2) _passo2(posicoesDisponiveis),
            if (step == 3) _passo3(),
            if (erro != null) ...[
              const SizedBox(height: 10),
              Text(erro!, style: const TextStyle(color: DalehColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (step > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OutlinedButton(
                      onPressed: () => setState(() => step -= 1),
                      child: const Text('Voltar'),
                    ),
                  ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: carregando
                        ? null
                        : () {
                            if (step < 3) {
                              setState(() {
                                _ajustarPosicoes();
                                step += 1;
                              });
                            } else {
                              _concluir();
                            }
                          },
                    child: Text(step == 3 ? (carregando ? 'Enviando…' : 'Concluir cadastro') : 'Continuar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem conta?', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
                TextButton(
                  onPressed: widget.onIrParaLogin,
                  child: const Text('Entrar', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passo1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'NOME COMPLETO')),
        const SizedBox(height: 12),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-MAIL'), keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        TextField(controller: senhaCtrl, decoration: const InputDecoration(labelText: 'SENHA'), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: telefoneCtrl, decoration: const InputDecoration(labelText: 'TELEFONE')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(flex: 2, child: TextField(controller: cidadeCtrl, decoration: const InputDecoration(labelText: 'CIDADE'))),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: estado,
                decoration: const InputDecoration(labelText: 'UF'),
                items: _estados.map((uf) => DropdownMenuItem(value: uf, child: Text(uf))).toList(),
                onChanged: (v) => setState(() => estado = v ?? estado),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passo2(List<String> posicoesDisponiveis) {
    Widget chips(List<String> opcoes, String? valorAtual, Set<String>? multi, void Function(String) onTap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: opcoes.map((o) {
          final ativo = multi != null ? multi.contains(o) : o == valorAtual;
          return ChoiceChip(
            label: Text(o),
            selected: ativo,
            onSelected: (_) => onTap(o),
            selectedColor: DalehColors.turf.withValues(alpha: 0.16),
            backgroundColor: DalehColors.surface2,
            labelStyle: TextStyle(color: ativo ? DalehColors.turf : DalehColors.muted, fontWeight: FontWeight.w700, fontSize: 12),
            side: BorderSide(color: ativo ? DalehColors.turf : DalehColors.line),
          );
        }).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MODALIDADES QUE JOGA', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        chips(_modalidades.map((m) => m['key'] as String).toList(), null, modalidadesSelecionadas, (k) {
          setState(() {
            if (modalidadesSelecionadas.contains(k)) {
              if (modalidadesSelecionadas.length > 1) modalidadesSelecionadas.remove(k);
            } else {
              modalidadesSelecionadas.add(k);
            }
            _ajustarPosicoes();
          });
        }),
        const SizedBox(height: 16),
        const Text('POSIÇÃO PRINCIPAL', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        chips(posicoesDisponiveis, posicao, null, (p) => setState(() => posicao = p)),
        const SizedBox(height: 16),
        const Text('POSIÇÃO SECUNDÁRIA', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        chips(posicoesDisponiveis, posicaoSec, null, (p) => setState(() => posicaoSec = p)),
        const SizedBox(height: 16),
        const Text('PÉ DOMINANTE', style: TextStyle(color: DalehColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        chips(const ['Direito', 'Esquerdo', 'Ambos'], pe, null, (p) => setState(() => pe = p)),
      ],
    );
  }

  Widget _passo3() {
    final modalidadesLabel = modalidadesSelecionadas
        .map((k) => (_modalidades.firstWhere((m) => m['key'] == k)['label']) as String)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DalehColors.surface2,
            border: Border.all(color: DalehColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nome: ${nomeCtrl.text.isEmpty ? '—' : nomeCtrl.text}'),
              Text('E-mail: ${emailCtrl.text.isEmpty ? '—' : emailCtrl.text}'),
              Text('Cidade: ${cidadeCtrl.text.isEmpty ? '—' : cidadeCtrl.text}/$estado'),
              Text('Modalidades: $modalidadesLabel'),
              Text('Posição: $posicao · $posicaoSec'),
              Text('Pé: $pe'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: consentimento,
          onChanged: (v) => setState(() => consentimento = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Autorizo o uso dos meus dados esportivos (posição, estatísticas, localização de jogos) '
            'conforme a LGPD, separado do aceite geral dos termos de uso.',
            style: TextStyle(color: DalehColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

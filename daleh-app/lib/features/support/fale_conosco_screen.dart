import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../theme/daleh_theme.dart';
import 'support_providers.dart';

const _categorias = [
  ('bug', 'Reportar um problema'),
  ('sugestao', 'Sugestão'),
  ('conta', 'Problema com minha conta'),
  ('suporte', 'Outro assunto'),
];

class FaleConoscoScreen extends ConsumerStatefulWidget {
  const FaleConoscoScreen({super.key});

  @override
  ConsumerState<FaleConoscoScreen> createState() => _FaleConoscoScreenState();
}

class _FaleConoscoScreenState extends ConsumerState<FaleConoscoScreen> {
  final _assuntoCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  String _categoria = _categorias.first.$1;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _assuntoCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_assuntoCtrl.text.trim().isEmpty || _mensagemCtrl.text.trim().isEmpty) {
      setState(() => _erro = 'Preenche o assunto e a mensagem antes de enviar.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(supportActionsProvider).enviarMensagem(
            categoria: _categoria,
            assunto: _assuntoCtrl.text.trim(),
            mensagem: _mensagemCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem enviada! Obrigado pelo retorno.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fale conosco')),
      body: ListView(
        padding: const EdgeInsets.all(DalehSpacing.lg),
        children: [
          const Text(
            'CATEGORIA',
            style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: DalehSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (chave, rotulo) in _categorias)
                ChoiceChip(
                  label: Text(rotulo),
                  selected: _categoria == chave,
                  onSelected: (_) => setState(() => _categoria = chave),
                ),
            ],
          ),
          const SizedBox(height: DalehSpacing.xl),
          TextField(
            controller: _assuntoCtrl,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Assunto'),
          ),
          const SizedBox(height: DalehSpacing.lg),
          TextField(
            controller: _mensagemCtrl,
            maxLength: 2000,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Mensagem', alignLabelWithHint: true),
          ),
          if (_erro != null) ...[
            const SizedBox(height: DalehSpacing.sm),
            Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
          ],
          const SizedBox(height: DalehSpacing.xl),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.bg),
                  )
                : const Text('ENVIAR'),
          ),
        ],
      ),
    );
  }
}

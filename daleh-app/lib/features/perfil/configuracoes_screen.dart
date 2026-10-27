import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../theme/daleh_theme.dart';
import '../auth/auth_controller.dart';
import '../support/fale_conosco_screen.dart';
import 'perfil_providers.dart';

const _palavraConfirmacao = 'EXCLUIR';

/// Perfil/apelido, Fale Conosco e exclusão de conta — tela separada do
/// Perfil pra deixar claro que é uma área de ajustes, não parte do fluxo
/// principal (edição de foto, trocar modo, sair). Parças virou aba própria
/// na navegação principal (ver `home_shell.dart`).
class ConfiguracoesScreen extends ConsumerWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(meuPerfilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(DalehSpacing.lg),
        children: [
          const Text(
            'PERFIL',
            style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: DalehSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.badge_outlined, color: DalehColors.turf),
              title: const Text('Apelido', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                perfilAsync.valueOrNull?.nickname ?? 'Nenhum apelido definido',
                style: const TextStyle(color: DalehColors.muted, fontSize: 12),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 18, color: DalehColors.muted),
              onTap: () => _editarApelido(context, ref, perfilAsync.valueOrNull?.nickname),
            ),
          ),
          const SizedBox(height: DalehSpacing.xl),
          const Text(
            'SUPORTE',
            style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: DalehSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.mail_outline, color: DalehColors.turf),
              title: const Text('Fale conosco', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Reportar um problema ou enviar sugestão', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaleConoscoScreen())),
            ),
          ),
          const SizedBox(height: DalehSpacing.xl),
          const Text(
            'CONTA',
            style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: DalehSpacing.sm),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: DalehColors.danger),
              title: const Text('Excluir minha conta', style: TextStyle(color: DalehColors.danger, fontWeight: FontWeight.w700)),
              subtitle: const Text(
                'Remove seus dados pessoais permanentemente. Não pode ser desfeito.',
                style: TextStyle(color: DalehColors.muted, fontSize: 12),
              ),
              onTap: () => _confirmarExclusao(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editarApelido(BuildContext context, WidgetRef ref, String? atual) async {
    final novoValor = await showDialog<String>(
      context: context,
      builder: (ctx) => _DialogoEditarApelido(valorAtual: atual),
    );
    if (novoValor == null || !context.mounted) return;

    try {
      await ref.read(perfilActionsProvider).atualizarApelido(novoValor.trim().isEmpty ? null : novoValor);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _DialogoConfirmacaoExclusao(),
    );
    if (confirmou != true || !context.mounted) return;

    final erro = await ref.read(authControllerProvider.notifier).excluirConta();
    if (!context.mounted) return;

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }
    // `excluirConta()` já desloga localmente — a `_Raiz` do app troca pra
    // tela de login sozinha assim que o estado muda, então só fecha esta
    // tela (se ainda estiver na pilha de navegação).
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }
}

class _DialogoEditarApelido extends StatefulWidget {
  final String? valorAtual;
  const _DialogoEditarApelido({this.valorAtual});

  @override
  State<_DialogoEditarApelido> createState() => _DialogoEditarApelidoState();
}

class _DialogoEditarApelidoState extends State<_DialogoEditarApelido> {
  late final _controlador = TextEditingController(text: widget.valorAtual ?? '');

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DalehColors.surface,
      title: const Text('Apelido'),
      content: TextField(
        controller: _controlador,
        maxLength: 30,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Como seus parças te chamam'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controlador.text),
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}

class _DialogoConfirmacaoExclusao extends StatefulWidget {
  const _DialogoConfirmacaoExclusao();

  @override
  State<_DialogoConfirmacaoExclusao> createState() => _DialogoConfirmacaoExclusaoState();
}

class _DialogoConfirmacaoExclusaoState extends State<_DialogoConfirmacaoExclusao> {
  final _controlador = TextEditingController();
  bool _confirmado = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DalehColors.surface,
      title: const Text('Excluir conta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu nome, foto, e-mail e dados de perfil serão removidos permanentemente e você não poderá mais entrar '
            'com esta conta. Jogos, convocações e estatísticas em que você participou continuam visíveis pro seu '
            'time (sem seus dados pessoais), porque fazem parte do histórico de outras pessoas.\n\n'
            'Essa ação não pode ser desfeita.',
            style: TextStyle(color: DalehColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: DalehSpacing.lg),
          Text(
            'Digite $_palavraConfirmacao pra confirmar:',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: DalehSpacing.sm),
          TextField(
            controller: _controlador,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (valor) => setState(() => _confirmado = valor.trim() == _palavraConfirmacao),
            decoration: const InputDecoration(hintText: _palavraConfirmacao),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: DalehColors.danger, foregroundColor: Colors.white),
          onPressed: _confirmado ? () => Navigator.of(context).pop(true) : null,
          child: const Text('EXCLUIR MINHA CONTA'),
        ),
      ],
    );
  }
}

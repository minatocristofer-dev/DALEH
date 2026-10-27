import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../theme/daleh_theme.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../auth/auth_controller.dart';
import 'configuracoes_screen.dart';
import 'editar_foto_screen.dart';
import 'models/meu_perfil.dart';
import 'perfil_providers.dart';
import 'posicoes.dart';
import 'widgets/player_card_com_compartilhar.dart';

const _pesDominantes = ['Direito', 'Esquerdo', 'Ambos'];

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(meuPerfilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        // "Sair" precisa estar sempre acessível, mesmo se o perfil não
        // carregar (erro de rede/servidor) — antes só existia dentro do
        // conteúdo carregado, deixando o usuário sem nenhum jeito de sair
        // da conta quando o `GET /auth/me` falhava.
        actions: [
          IconButton(
            tooltip: 'Trocar foto de perfil',
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditarFotoScreen())),
          ),
          IconButton(
            tooltip: 'Trocar modo',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(authControllerProvider.notifier).abrirSeletorDeModo(),
          ),
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfiguracoesScreen())),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(meuPerfilProvider),
        child: perfilAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(meuPerfilProvider))],
          ),
          data: (perfil) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PlayerCardComCompartilhar(perfil: perfil),
              const SizedBox(height: DalehSpacing.xl),
              _SecaoDados(perfil: perfil),
            ],
          ),
        ),
      ),
    );
  }
}

/// Apelido, pé dominante e posição — ficam direto no Perfil (antes viviam
/// escondidos dentro de Configurações, difícil de achar e editar).
class _SecaoDados extends ConsumerWidget {
  final MeuPerfil perfil;
  const _SecaoDados({required this.perfil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modalidade = perfil.modalidadePrincipal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DADOS',
          style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: DalehSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined, color: DalehColors.turf),
                title: const Text('Apelido', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  perfil.nickname ?? 'Nenhum apelido definido',
                  style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18, color: DalehColors.muted),
                onTap: () => _editarApelido(context, ref, perfil.nickname),
              ),
              const Divider(color: DalehColors.line, height: 1),
              ListTile(
                leading: const Icon(Icons.sports_soccer_outlined, color: DalehColors.turf),
                title: const Text('Perna dominante', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  perfil.dominantFoot ?? 'Não definida',
                  style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18, color: DalehColors.muted),
                onTap: () => _editarPeDominante(context, ref, perfil.dominantFoot),
              ),
              if (modalidade != null) ...[
                const Divider(color: DalehColors.line, height: 1),
                ListTile(
                  leading: const Icon(Icons.sports_outlined, color: DalehColors.turf),
                  title: const Text('Posição', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    modalidade.posicaoSecundaria != null
                        ? '${modalidade.posicaoPrincipal} · ${modalidade.posicaoSecundaria}'
                        : modalidade.posicaoPrincipal,
                    style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18, color: DalehColors.muted),
                  onTap: () => _editarPosicao(context, ref, modalidade),
                ),
              ],
            ],
          ),
        ),
      ],
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

  Future<void> _editarPeDominante(BuildContext context, WidgetRef ref, String? atual) async {
    final novoValor = await showDialog<String>(
      context: context,
      builder: (ctx) => _DialogoEscolhaUnica(titulo: 'Perna dominante', opcoes: _pesDominantes, valorAtual: atual),
    );
    if (novoValor == null || !context.mounted) return;

    try {
      await ref.read(perfilActionsProvider).atualizarPeDominante(novoValor);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editarPosicao(BuildContext context, WidgetRef ref, ModalidadeJogador modalidade) async {
    final opcoes = posicoesPorModalidade[modalidade.modalidade] ?? const <String>[];
    final resultado = await showDialog<(String, String?)>(
      context: context,
      builder: (ctx) => _DialogoEditarPosicao(
        opcoes: opcoes,
        posicaoPrincipalAtual: modalidade.posicaoPrincipal,
        posicaoSecundariaAtual: modalidade.posicaoSecundaria,
      ),
    );
    if (resultado == null || !context.mounted) return;

    try {
      await ref.read(perfilActionsProvider).atualizarPosicao(modalidade.modalidade, resultado.$1, resultado.$2);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

/// Diálogo genérico de escolha única em chips — usado hoje só pra perna
/// dominante, mas sem nada específico de pé nele.
class _DialogoEscolhaUnica extends StatefulWidget {
  final String titulo;
  final List<String> opcoes;
  final String? valorAtual;
  const _DialogoEscolhaUnica({required this.titulo, required this.opcoes, this.valorAtual});

  @override
  State<_DialogoEscolhaUnica> createState() => _DialogoEscolhaUnicaState();
}

class _DialogoEscolhaUnicaState extends State<_DialogoEscolhaUnica> {
  late String selecionado = widget.opcoes.contains(widget.valorAtual) ? widget.valorAtual! : widget.opcoes.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DalehColors.surface,
      title: Text(widget.titulo),
      content: Wrap(
        spacing: 8,
        children: widget.opcoes
            .map((o) => ChoiceChip(
                  label: Text(o),
                  selected: selecionado == o,
                  onSelected: (_) => setState(() => selecionado = o),
                ))
            .toList(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.of(context).pop(selecionado), child: const Text('SALVAR')),
      ],
    );
  }
}

class _DialogoEditarPosicao extends StatefulWidget {
  final List<String> opcoes;
  final String posicaoPrincipalAtual;
  final String? posicaoSecundariaAtual;
  const _DialogoEditarPosicao({
    required this.opcoes,
    required this.posicaoPrincipalAtual,
    this.posicaoSecundariaAtual,
  });

  @override
  State<_DialogoEditarPosicao> createState() => _DialogoEditarPosicaoState();
}

class _DialogoEditarPosicaoState extends State<_DialogoEditarPosicao> {
  late String principal =
      widget.opcoes.contains(widget.posicaoPrincipalAtual) ? widget.posicaoPrincipalAtual : widget.opcoes.first;
  late String? secundaria =
      widget.opcoes.contains(widget.posicaoSecundariaAtual) ? widget.posicaoSecundariaAtual : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DalehColors.surface,
      title: const Text('Posição'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Principal', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.opcoes
                .map((o) => ChoiceChip(
                      key: ValueKey('posicao-principal-$o'),
                      label: Text(o),
                      selected: principal == o,
                      onSelected: (_) => setState(() {
                        principal = o;
                        if (secundaria == o) secundaria = null;
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('Secundária (opcional)', style: TextStyle(color: DalehColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.opcoes
                .where((o) => o != principal)
                .map((o) => ChoiceChip(
                      key: ValueKey('posicao-secundaria-$o'),
                      label: Text(o),
                      selected: secundaria == o,
                      onSelected: (_) => setState(() => secundaria = secundaria == o ? null : o),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((principal, secundaria)),
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}

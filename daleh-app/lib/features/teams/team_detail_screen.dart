import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/member_row.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/status_chip.dart';
import '../../theme/daleh_theme.dart';
import 'call_ups_tab.dart';
import 'editar_escudo_screen.dart';
import 'models/team_member.dart';
import 'teams_providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(teamDetailProvider(teamId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(detailAsync.maybeWhen(data: (d) => d.name, orElse: () => 'Time')),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'VISÃO GERAL'),
              Tab(text: 'ELENCO'),
              Tab(text: 'CONVOCAÇÕES'),
            ],
          ),
        ),
        body: detailAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(teamDetailProvider(teamId))),
          data: (detail) {
            final meuUserId = ref.watch(meuUserIdProvider);
            final souDono = meuUserId != null && detail.souDono(meuUserId);
            final possoGerenciar = meuUserId != null && detail.possoGerenciar(meuUserId);

            return TabBarView(
              children: [
                _VisaoGeralTab(detail: detail, souDono: souDono, possoGerenciar: possoGerenciar),
                _ElencoTab(teamId: teamId, detail: detail, meuUserId: meuUserId, possoGerenciar: possoGerenciar),
                CallUpsTab(teamId: teamId, possoGerenciar: possoGerenciar),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VisaoGeralTab extends StatelessWidget {
  final TeamDetail detail;
  final bool souDono;
  final bool possoGerenciar;
  const _VisaoGeralTab({required this.detail, required this.souDono, required this.possoGerenciar});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final localizacao = [d.city, d.state].where((v) => v != null && v.isNotEmpty).join(' / ');
    TeamMember? dono;
    for (final m in d.members) {
      if (m.userId == d.ownerId) dono = m;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            children: [
              CrestAvatar(url: d.crestUrl, nome: d.name, tamanho: 88),
              // Só quem pode gerenciar o time (dono/capitão/vice) vê o
              // botão de trocar o escudo — mesma regra checada no backend.
              if (possoGerenciar)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditarEscudoScreen(teamId: d.id)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: DalehColors.turf, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: DalehColors.bg),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22), textAlign: TextAlign.center),
        ),
        if (localizacao.isNotEmpty) ...[
          const SizedBox(height: 4),
          Center(child: Text(localizacao, style: const TextStyle(color: DalehColors.muted))),
        ],
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _linhaInfo('Jogadores no elenco', '${d.members.length}'),
                const Divider(color: DalehColors.line, height: 24),
                _linhaInfo('Administrador do time', dono?.fullName ?? '—'),
                if (souDono) ...[
                  const Divider(color: DalehColors.line, height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [StatusChip(texto: 'VOCÊ É O ADMINISTRADOR', cor: DalehColors.amber)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _linhaInfo(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: DalehColors.muted)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ElencoTab extends ConsumerWidget {
  final String teamId;
  final TeamDetail detail;
  final String? meuUserId;
  final bool possoGerenciar;

  const _ElencoTab({
    required this.teamId,
    required this.detail,
    required this.meuUserId,
    required this.possoGerenciar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: possoGerenciar
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarAdicionarMembro(context, ref, teamId),
              backgroundColor: DalehColors.turf,
              foregroundColor: DalehColors.bg,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar jogador'),
            )
          : null,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: detail.members.length,
        separatorBuilder: (_, _) => const Divider(color: DalehColors.line),
        itemBuilder: (context, i) {
          final membro = detail.members[i];
          final ehDono = membro.userId == detail.ownerId;
          final souEuMesmo = membro.userId == meuUserId;
          return MemberRow(
            membro: membro,
            ehDono: ehDono,
            possoGerenciar: possoGerenciar,
            souEuMesmo: souEuMesmo,
            onAlterarPapel: (novoPapel) async {
              try {
                await ref.read(teamsActionsProvider).atualizarPapel(teamId, membro.userId, novoPapel);
              } on ApiException catch (e) {
                if (context.mounted) _mostrarErro(context, e);
              }
            },
            onRemover: () => _confirmarRemocao(context, ref, teamId, membro, souEuMesmo),
            onEditarNumero: () => _editarNumero(context, ref, teamId, membro),
          );
        },
      ),
    );
  }

  void _mostrarErro(BuildContext context, ApiException e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }

  // Quem escolhe o número é o administrador/capitão, nunca o próprio
  // jogador — por isso esse diálogo só aparece a partir do menu de gestão
  // do elenco, não em nenhuma tela que o jogador acesse sobre si mesmo.
  Future<void> _editarNumero(BuildContext context, WidgetRef ref, String teamId, TeamMember membro) async {
    final controlador = TextEditingController(text: membro.numeroCamisa?.toString() ?? '');
    String? erro;

    final numero = await showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Número da camisa — ${membro.fullName}'),
            content: TextField(
              controller: controlador,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Número', errorText: erro),
            ),
            actions: [
              if (membro.numeroCamisa != null)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Limpar', style: TextStyle(color: DalehColors.danger)),
                ),
              TextButton(onPressed: () => Navigator.of(ctx).pop(membro.numeroCamisa), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  final texto = controlador.text.trim();
                  if (texto.isEmpty) {
                    Navigator.of(ctx).pop(null);
                    return;
                  }
                  final valor = int.tryParse(texto);
                  if (valor == null || valor < 0) {
                    setState(() => erro = 'Digite um número válido.');
                    return;
                  }
                  Navigator.of(ctx).pop(valor);
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    // Cancelar devolve o número atual sem mudar nada — só chama a API se o
    // valor realmente for diferente do que já estava.
    if (numero == membro.numeroCamisa) return;

    final erroApi = await ref.read(teamsActionsProvider).definirNumeroCamisa(teamId, membro.userId, membro.papel, numero);
    if (erroApi != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erroApi)));
    }
  }

  Future<void> _confirmarRemocao(
    BuildContext context,
    WidgetRef ref,
    String teamId,
    TeamMember membro,
    bool souEuMesmo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(souEuMesmo ? 'Sair do time?' : 'Remover ${membro.fullName}?'),
        content: Text(souEuMesmo
            ? 'Você vai deixar de fazer parte deste time.'
            : '${membro.fullName} vai deixar de fazer parte deste time.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar', style: TextStyle(color: DalehColors.danger)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(teamsActionsProvider).removerMembro(teamId, membro.userId);
    } on ApiException catch (e) {
      if (context.mounted) _mostrarErro(context, e);
    }
  }

  Future<void> _mostrarAdicionarMembro(BuildContext context, WidgetRef ref, String teamId) async {
    final emailCtrl = TextEditingController();
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
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Adicionar jogador', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'O jogador precisa já ter uma conta no DALEH. Ainda não existe busca por nome — use o e-mail cadastrado por ele.',
                    style: TextStyle(color: DalehColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail do jogador'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Adicionar',
                    carregando: enviando,
                    onPressed: () async {
                      if (emailCtrl.text.trim().isEmpty) {
                        setState(() => erro = 'Informe um e-mail.');
                        return;
                      }
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(teamsActionsProvider).adicionarMembro(teamId, email: emailCtrl.text.trim());
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

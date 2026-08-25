import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../shared/widgets/call_up_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'teams_providers.dart';

/// Visão de gestão das convocações de um time (captão/dono). A confirmação
/// e recusa de cada convocação é feita pelo próprio jogador convocado, na
/// aba "Convocações" do Perfil dele — não aqui.
class CallUpsTab extends ConsumerWidget {
  final String teamId;
  final bool possoGerenciar;

  const CallUpsTab({super.key, required this.teamId, required this.possoGerenciar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callUpsAsync = ref.watch(convocacoesDoTimeProvider(teamId));

    return Scaffold(
      floatingActionButton: possoGerenciar
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarNovaConvocacao(context, ref, teamId),
              backgroundColor: DalehColors.turf,
              foregroundColor: DalehColors.bg,
              icon: const Icon(Icons.campaign),
              label: const Text('Convocar elenco'),
            )
          : null,
      body: callUpsAsync.when(
        loading: () => const LoadingState(),
        error: (erro, _) => ListView(
          children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(convocacoesDoTimeProvider(teamId)))],
        ),
        data: (callUps) {
          if (callUps.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                EmptyState(
                  icon: Icons.campaign_outlined,
                  titulo: 'Nenhuma convocação ainda',
                  subtitulo: 'Quando você convocar o elenco pra um jogo, as convocações aparecem aqui.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: callUps.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CallUpCard(callUp: callUps[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarNovaConvocacao(BuildContext context, WidgetRef ref, String teamId) async {
    final localCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
    DateTime? dataEscolhida;
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
                  const Text('Convocar elenco', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Todo o elenco ativo do time recebe essa convocação.',
                    style: TextStyle(color: DalehColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: localCtrl,
                    decoration: const InputDecoration(labelText: 'Local (ex: Arena Society Centro)'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final agora = DateTime.now();
                      final escolhida = await showDatePicker(
                        context: ctx,
                        initialDate: agora,
                        firstDate: agora,
                        lastDate: agora.add(const Duration(days: 365)),
                      );
                      if (escolhida != null) setState(() => dataEscolhida = escolhida);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data'),
                      child: Text(
                        dataEscolhida == null
                            ? 'Escolher data'
                            : '${dataEscolhida!.day.toString().padLeft(2, '0')}/${dataEscolhida!.month.toString().padLeft(2, '0')}/${dataEscolhida!.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: horaCtrl,
                    decoration: const InputDecoration(labelText: 'Horário (ex: 20:00)'),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 12),
                    Text(erro!, style: const TextStyle(color: DalehColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Enviar convocação',
                    carregando: enviando,
                    onPressed: () async {
                      if (localCtrl.text.trim().isEmpty || dataEscolhida == null || horaCtrl.text.trim().isEmpty) {
                        setState(() => erro = 'Preencha local, data e horário.');
                        return;
                      }
                      setState(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await ref.read(teamsActionsProvider).convocar(
                              teamId,
                              venueNameSnapshot: localCtrl.text.trim(),
                              scheduledDate: dataEscolhida!.toIso8601String(),
                              scheduledTime: horaCtrl.text.trim(),
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

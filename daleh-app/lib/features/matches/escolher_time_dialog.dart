import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../teams/teams_providers.dart';

/// Diálogo simples de "qual dos meus times" — reaproveitado por Criar Desafio
/// e Solicitar Desafio. Só lista times onde o usuário está (o backend ainda
/// decide, via exigirCapitaoOuDono, se ele pode agir por aquele time).
Future<String?> escolherTimeDialog(BuildContext context, WidgetRef ref, {required String titulo}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, _) {
              final timesAsync = ref.watch(meusTimesProvider);
              return timesAsync.when(
                loading: () => const LoadingState(),
                error: (erro, _) => ErrorState(erro: erro),
                data: (times) {
                  if (times.isEmpty) {
                    return const EmptyState(
                      icon: Icons.shield_outlined,
                      titulo: 'Você não tem times',
                      subtitulo: 'Crie um time primeiro, na aba Times.',
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: times.length,
                    itemBuilder: (context, i) {
                      final time = times[i];
                      return ListTile(
                        leading: CrestAvatar(url: time.crestUrl, nome: time.name, tamanho: 36),
                        title: Text(time.name),
                        subtitle: Text(time.meuPapel ?? ''),
                        onTap: () => Navigator.of(ctx).pop(time.id),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        ],
      );
    },
  );
}

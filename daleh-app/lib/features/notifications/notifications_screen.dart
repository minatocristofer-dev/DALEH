import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_state.dart';
import '../../theme/daleh_theme.dart';
import 'models/app_notification.dart';
import 'notification_navigator.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificacoesAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificacoesAsync.when(
          loading: () => const LoadingState(),
          error: (erro, _) => ListView(
            children: [ErrorState(erro: erro, onTentarNovamente: () => ref.invalidate(notificationsProvider))],
          ),
          data: (notificacoes) {
            if (notificacoes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.notifications_none,
                    titulo: 'Nenhuma notificação ainda',
                    subtitulo: 'Avisos sobre seus times e convocações aparecem aqui.',
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: notificacoes.length,
              separatorBuilder: (_, _) => const Divider(color: DalehColors.line, height: 1),
              itemBuilder: (context, i) => _NotificationTile(notificacao: notificacoes[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notificacao;
  const _NotificationTile({required this.notificacao});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        notificacao.lida ? Icons.notifications_none : Icons.notifications,
        color: notificacao.lida ? DalehColors.muted : DalehColors.turf,
      ),
      title: Text(
        notificacao.titulo,
        style: TextStyle(fontWeight: notificacao.lida ? FontWeight.w500 : FontWeight.w900),
      ),
      subtitle: Text(notificacao.corpo, style: const TextStyle(color: DalehColors.muted)),
      onTap: () => _abrir(context, ref),
    );
  }

  // Marca como lida só na primeira vez (evita chamada duplicada à API) mas
  // sempre tenta navegar, mesmo pra notificação já lida — o toque nunca
  // remove o item da lista.
  void _abrir(BuildContext context, WidgetRef ref) {
    if (!notificacao.lida) {
      ref.read(notificationsActionsProvider).marcarLida(notificacao.id);
    }
    final destino = resolverDestinoDaNotificacao(notificacao.type, notificacao.payload);
    if (destino != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino));
    }
  }
}

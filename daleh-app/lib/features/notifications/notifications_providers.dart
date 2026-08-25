import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'models/app_notification.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref.read(apiClientProvider)));

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  final repo = ref.read(notificationsRepositoryProvider);
  return comSessao(ref, (token) => repo.listarMinhas(token));
});

final notificacoesNaoLidasProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (lista) => lista.where((n) => !n.lida).length,
        orElse: () => 0,
      );
});

class NotificationsActions {
  final Ref ref;
  NotificationsActions(this.ref);

  Future<void> marcarLida(String id) async {
    final repo = ref.read(notificationsRepositoryProvider);
    await comSessao(ref, (token) => repo.marcarLida(id, token));
    ref.invalidate(notificationsProvider);
  }
}

final notificationsActionsProvider = Provider((ref) => NotificationsActions(ref));

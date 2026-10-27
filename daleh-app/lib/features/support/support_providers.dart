import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'support_repository.dart';

final supportRepositoryProvider = Provider((ref) => SupportRepository(ref.read(apiClientProvider)));

class SupportActions {
  final Ref ref;
  SupportActions(this.ref);

  Future<void> enviarMensagem({required String categoria, required String assunto, required String mensagem}) {
    final repo = ref.read(supportRepositoryProvider);
    return comSessao(
      ref,
      (token) => repo.enviarMensagem(categoria: categoria, assunto: assunto, mensagem: mensagem, token: token),
    );
  }
}

final supportActionsProvider = Provider((ref) => SupportActions(ref));

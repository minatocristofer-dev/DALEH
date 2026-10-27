import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'models/parca.dart';
import 'parcas_repository.dart';

final parcasRepositoryProvider = Provider((ref) => ParcasRepository(ref.read(apiClientProvider)));

final seguindoProvider = FutureProvider.autoDispose<List<Parca>>((ref) {
  final repo = ref.read(parcasRepositoryProvider);
  return comSessao(ref, (token) => repo.seguindo(token));
});

final seguidoresProvider = FutureProvider.autoDispose<List<Parca>>((ref) {
  final repo = ref.read(parcasRepositoryProvider);
  return comSessao(ref, (token) => repo.seguidores(token));
});

/// Ações que alteram estado no backend — mesmo padrão de `TeamsActions`:
/// guarda um `Ref` de verdade (não `WidgetRef`), pra poder usar `comSessao`.
class ParcasActions {
  final Ref ref;
  ParcasActions(this.ref);

  ParcasRepository get _repo => ref.read(parcasRepositoryProvider);

  Future<void> seguir(String userId) async {
    await comSessao(ref, (token) => _repo.seguir(userId, token));
    ref.invalidate(seguindoProvider);
  }

  Future<void> deixarDeSeguir(String userId) async {
    await comSessao(ref, (token) => _repo.deixarDeSeguir(userId, token));
    ref.invalidate(seguindoProvider);
  }
}

final parcasActionsProvider = Provider((ref) => ParcasActions(ref));

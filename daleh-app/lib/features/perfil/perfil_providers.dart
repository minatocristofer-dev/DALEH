import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'perfil_repository.dart';
import 'models/meu_perfil.dart';

final perfilRepositoryProvider = Provider((ref) => PerfilRepository(ref.read(apiClientProvider)));

final meuPerfilProvider = FutureProvider.autoDispose<MeuPerfil>((ref) {
  final repo = ref.read(perfilRepositoryProvider);
  return comSessao(ref, (token) => repo.meuPerfil(token));
});

final perfilPublicoProvider = FutureProvider.autoDispose.family<MeuPerfil, String>((ref, userId) {
  final repo = ref.read(perfilRepositoryProvider);
  return comSessao(ref, (token) => repo.perfilPublico(userId, token));
});

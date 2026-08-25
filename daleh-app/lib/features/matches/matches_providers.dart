import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'matches_repository.dart';
import 'models/match.dart';
import 'models/match_event.dart';

final matchesRepositoryProvider = Provider((ref) => MatchesRepository(ref.read(apiClientProvider)));

final minhasPartidasProvider = FutureProvider.autoDispose<List<Match>>((ref) {
  final repo = ref.read(matchesRepositoryProvider);
  return comSessao(ref, (token) => repo.minhasPartidas(token));
});

final partidaDetalheProvider = FutureProvider.autoDispose.family<Match, String>((ref, matchId) {
  final repo = ref.read(matchesRepositoryProvider);
  return comSessao(ref, (token) => repo.obterPartida(matchId, token));
});

class MatchesActions {
  final Ref ref;
  MatchesActions(this.ref);

  MatchesRepository get _repo => ref.read(matchesRepositoryProvider);

  Future<Match> criarPartida({
    required String modalidade,
    String? venueId,
    required String scheduledAt,
    int? maxPlayers,
    String visibility = 'public',
  }) async {
    final partida = await comSessao(
      ref,
      (token) => _repo.criarPartida(
        token,
        modalidade: modalidade,
        venueId: venueId,
        scheduledAt: scheduledAt,
        maxPlayers: maxPlayers,
        visibility: visibility,
      ),
    );
    ref.invalidate(minhasPartidasProvider);
    return partida;
  }

  Future<void> confirmarPresenca(String matchId) async {
    await comSessao(ref, (token) => _repo.confirmarPresenca(matchId, token));
    ref.invalidate(partidaDetalheProvider(matchId));
    ref.invalidate(minhasPartidasProvider);
  }

  Future<void> cancelarPresenca(String matchId) async {
    await comSessao(ref, (token) => _repo.cancelarPresenca(matchId, token));
    ref.invalidate(partidaDetalheProvider(matchId));
    ref.invalidate(minhasPartidasProvider);
  }

  Future<void> atualizarStatus(String matchId, String status) async {
    await comSessao(ref, (token) => _repo.atualizarStatus(matchId, token, status: status));
    ref.invalidate(partidaDetalheProvider(matchId));
    ref.invalidate(minhasPartidasProvider);
  }

  Future<MatchEvent> registrarEvento(String matchId, {required String userId, required String eventType, int? minute}) async {
    final evento = await comSessao(
      ref,
      (token) => _repo.registrarEvento(matchId, token, userId: userId, eventType: eventType, minute: minute),
    );
    ref.invalidate(partidaDetalheProvider(matchId));
    return evento;
  }

  Future<void> registrarGol(String matchId, {required String scorerId, String? assistId, int? minute}) async {
    await comSessao(
      ref,
      (token) => _repo.registrarGol(matchId, token, scorerId: scorerId, assistId: assistId, minute: minute),
    );
    ref.invalidate(partidaDetalheProvider(matchId));
  }

  Future<void> elegerMvp(String matchId, {required String userId}) async {
    await comSessao(ref, (token) => _repo.elegerMvp(matchId, token, userId: userId));
    ref.invalidate(partidaDetalheProvider(matchId));
  }
}

final matchesActionsProvider = Provider((ref) => MatchesActions(ref));

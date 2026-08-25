import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session_guard.dart';
import '../auth/auth_controller.dart';
import 'challenges_repository.dart';
import 'models/meus_desafios.dart';
import 'models/team_challenge.dart';

final challengesRepositoryProvider = Provider((ref) => ChallengesRepository(ref.read(apiClientProvider)));

final desafiosAbertosProvider = FutureProvider.autoDispose<List<TeamChallenge>>((ref) {
  final repo = ref.read(challengesRepositoryProvider);
  return comSessao(ref, (token) => repo.listarDesafios(token));
});

final meusDesafiosProvider = FutureProvider.autoDispose<MeusDesafios>((ref) {
  final repo = ref.read(challengesRepositoryProvider);
  return comSessao(ref, (token) => repo.meusDesafios(token));
});

class ChallengesActions {
  final Ref ref;
  ChallengesActions(this.ref);

  ChallengesRepository get _repo => ref.read(challengesRepositoryProvider);

  Future<TeamChallenge> criarDesafio({
    required String teamId,
    required String modalidade,
    required String city,
    String? venueId,
    required String scheduledDate,
    required String scheduledTime,
    required String desiredLevel,
  }) async {
    final desafio = await comSessao(
      ref,
      (token) => _repo.criarDesafio(
        token,
        teamId: teamId,
        modalidade: modalidade,
        city: city,
        venueId: venueId,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        desiredLevel: desiredLevel,
      ),
    );
    ref.invalidate(desafiosAbertosProvider);
    ref.invalidate(meusDesafiosProvider);
    return desafio;
  }

  Future<void> solicitar(String challengeId, {required String requestingTeamId}) async {
    await comSessao(ref, (token) => _repo.solicitar(challengeId, token, requestingTeamId: requestingTeamId));
    ref.invalidate(meusDesafiosProvider);
  }

  Future<void> aceitar(String challengeId, String requestId) async {
    await comSessao(ref, (token) => _repo.aceitar(challengeId, requestId, token));
    ref.invalidate(meusDesafiosProvider);
    ref.invalidate(desafiosAbertosProvider);
  }
}

final challengesActionsProvider = Provider((ref) => ChallengesActions(ref));

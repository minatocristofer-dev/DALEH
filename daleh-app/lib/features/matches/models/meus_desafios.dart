import 'challenge_request.dart';
import 'team_challenge.dart';

/// Espelha o retorno de GET /team-challenges/mine: dois grupos, não uma lista única.
class MeusDesafios {
  final List<TeamChallenge> comoOrganizador;
  final List<ChallengeRequest> minhasSolicitacoes;

  MeusDesafios({required this.comoOrganizador, required this.minhasSolicitacoes});

  factory MeusDesafios.fromJson(Map<String, dynamic> json) => MeusDesafios(
        comoOrganizador: (json['comoOrganizador'] as List? ?? [])
            .map((d) => TeamChallenge.fromJson(d as Map<String, dynamic>))
            .toList(),
        minhasSolicitacoes: (json['minhasSolicitacoes'] as List? ?? [])
            .map((r) => ChallengeRequest.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

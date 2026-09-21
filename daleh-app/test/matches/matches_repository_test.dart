import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/matches/matches_repository.dart';
import 'package:daleh_app/features/matches/challenges_repository.dart';

class _Chamada {
  final String metodo;
  final String path;
  final Map<String, dynamic>? corpo;
  _Chamada(this.metodo, this.path, this.corpo);
}

class FakeApiClient implements ApiClient {
  final List<_Chamada> chamadas = [];
  final Map<String, dynamic> respostas;
  FakeApiClient({this.respostas = const {}});

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) async {
    chamadas.add(_Chamada('GET', path, null));
    return (respostas[path] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async {
    chamadas.add(_Chamada('GET', path, null));
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_Chamada('POST', path, corpo));
    return respostas[path];
  }

  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_Chamada('PATCH', path, corpo));
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    chamadas.add(_Chamada('DELETE', path, null));
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> enviarArquivo(
    String path, {
    required String token,
    required List<int> bytes,
    required String nomeArquivo,
  }) =>
      throw UnimplementedError();
}

void main() {
  const token = 'token-de-teste';

  group('MatchesRepository', () {
    test('criarPartida só envia os campos preenchidos', () async {
      final fake = FakeApiClient(respostas: {
        '/matches': {
          'id': 'match-1',
          'createdById': 'user-1',
          'modalidadeId': 'modalidade-1',
          'scheduledAt': '2026-09-10T20:00:00.000Z',
          'status': 'scheduled',
          'visibility': 'public',
        },
      });
      final repo = MatchesRepository(fake);

      await repo.criarPartida(token, modalidade: 'SOCIETY', scheduledAt: '2026-09-10T20:00:00.000Z');

      final chamada = fake.chamadas.single;
      expect(chamada.corpo, {
        'modalidade': 'SOCIETY',
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'visibility': 'public',
      });
    });

    test('confirmarPresenca chama POST /matches/:id/attendance sem corpo', () async {
      final fake = FakeApiClient();
      final repo = MatchesRepository(fake);

      await repo.confirmarPresenca('match-1', token);

      expect(fake.chamadas.single.metodo, 'POST');
      expect(fake.chamadas.single.path, '/matches/match-1/attendance');
    });

    test('registrarEvento envia userId/eventType/minute', () async {
      final fake = FakeApiClient(respostas: {
        '/matches/match-1/events': {
          'id': 'evt-1',
          'matchId': 'match-1',
          'userId': 'user-1',
          'eventType': 'goal',
          'minute': 10,
          'createdAt': '2026-08-25T00:00:00.000Z',
        },
      });
      final repo = MatchesRepository(fake);

      final evento = await repo.registrarEvento('match-1', token, userId: 'user-1', eventType: 'goal', minute: 10);

      expect(evento.eventType, 'goal');
      expect(fake.chamadas.single.corpo, {'userId': 'user-1', 'eventType': 'goal', 'minute': 10});
    });
  });

  group('ChallengesRepository', () {
    test('listarDesafios monta a query string só com os filtros informados', () async {
      final fake = FakeApiClient();
      final repo = ChallengesRepository(fake);

      await repo.listarDesafios(token, city: 'Santa Maria');

      expect(fake.chamadas.single.path, '/team-challenges?city=Santa+Maria');
    });

    test('solicitar envia requestingTeamId no corpo', () async {
      final fake = FakeApiClient(respostas: {
        '/team-challenges/desafio-1/requests': {
          'id': 'req-1',
          'challengeId': 'desafio-1',
          'requestingTeamId': 'time-b',
          'status': 'PENDENTE',
          'createdAt': '2026-08-21T00:00:00.000Z',
        },
      });
      final repo = ChallengesRepository(fake);

      await repo.solicitar('desafio-1', token, requestingTeamId: 'time-b');

      expect(fake.chamadas.single.corpo, {'requestingTeamId': 'time-b'});
    });

    test('aceitar chama o endpoint de accept e devolve o desafio confirmado com matchId', () async {
      final fake = FakeApiClient(respostas: {
        '/team-challenges/desafio-1/requests/req-1/accept': {
          'id': 'desafio-1',
          'teamId': 'time-a',
          'city': 'Santa Maria',
          'scheduledDate': '2026-09-15T00:00:00.000Z',
          'scheduledTime': '19:30',
          'desiredLevel': 'intermediario',
          'status': 'CONFIRMADA',
          'matchId': 'match-novo',
        },
      });
      final repo = ChallengesRepository(fake);

      final desafio = await repo.aceitar('desafio-1', 'req-1', token);

      expect(desafio.confirmada, isTrue);
      expect(desafio.matchId, 'match-novo');
      expect(fake.chamadas.single.path, '/team-challenges/desafio-1/requests/req-1/accept');
    });
  });
}

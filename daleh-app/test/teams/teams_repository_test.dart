import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/teams/teams_repository.dart';

class _ChamadaRegistrada {
  final String metodo;
  final String path;
  final Map<String, dynamic>? corpo;
  final String? token;
  _ChamadaRegistrada(this.metodo, this.path, this.corpo, this.token);
}

/// Substitui o ApiClient real por um que nunca faz rede — devolve respostas
/// programadas e grava as chamadas recebidas, pra testar o repositório sem
/// depender da API real nem de infraestrutura de sessão (Riverpod/Supabase).
class FakeApiClient implements ApiClient {
  final List<_ChamadaRegistrada> chamadas = [];
  final Map<String, dynamic> respostas;
  ApiException? erroParaLancar;

  FakeApiClient({this.respostas = const {}});

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) async {
    chamadas.add(_ChamadaRegistrada('GET', path, null, token));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async {
    chamadas.add(_ChamadaRegistrada('GET', path, null, token));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_ChamadaRegistrada('POST', path, corpo, token));
    if (erroParaLancar != null) throw erroParaLancar!;
    return respostas[path];
  }

  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_ChamadaRegistrada('PATCH', path, corpo, token));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    chamadas.add(_ChamadaRegistrada('DELETE', path, null, token));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {'removido': true};
  }

  // Não usados pelo TeamsRepository — implementados só pra satisfazer a interface.
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
}

void main() {
  const token = 'token-de-teste';

  group('TeamsRepository', () {
    test('listarMeusTimes faz GET /teams/mine e converte cada item', () async {
      final fake = FakeApiClient(respostas: {
        '/teams/mine': [
          {
            'id': 'time-1',
            'name': 'DALEH FC',
            'crestUrl': null,
            'city': 'Santa Maria',
            'state': 'RS',
            'ownerId': 'user-1',
            'meuPapel': 'CAPITAO',
            'totalMembros': 12,
          },
        ],
      });
      final repo = TeamsRepository(fake);

      final times = await repo.listarMeusTimes(token);

      expect(times, hasLength(1));
      expect(times.first.name, 'DALEH FC');
      expect(fake.chamadas.single.metodo, 'GET');
      expect(fake.chamadas.single.path, '/teams/mine');
      expect(fake.chamadas.single.token, token);
    });

    test('criarTime faz POST /teams só com os campos preenchidos', () async {
      final fake = FakeApiClient(respostas: {
        '/teams': {
          'id': 'time-novo',
          'name': 'Time Novo',
          'crestUrl': null,
          'city': null,
          'state': null,
          'ownerId': 'user-1',
        },
      });
      final repo = TeamsRepository(fake);

      final time = await repo.criarTime(token, name: 'Time Novo');

      expect(time.id, 'time-novo');
      final chamada = fake.chamadas.single;
      expect(chamada.corpo, {'name': 'Time Novo'});
    });

    test('adicionarMembro por e-mail envia só o e-mail no corpo', () async {
      final fake = FakeApiClient();
      final repo = TeamsRepository(fake);

      await repo.adicionarMembro('time-1', token, email: 'jogador@teste.com');

      final chamada = fake.chamadas.single;
      expect(chamada.metodo, 'POST');
      expect(chamada.path, '/teams/time-1/members');
      expect(chamada.corpo, {'email': 'jogador@teste.com'});
    });

    test('removerMembro propaga ApiException de 403 (usuário sem permissão)', () async {
      final fake = FakeApiClient()..erroParaLancar = ApiException('Sem permissão', kind: ApiErrorKind.forbidden);
      final repo = TeamsRepository(fake);

      expect(
        () => repo.removerMembro('time-1', 'user-alvo', token),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.forbidden)),
      );
    });

    test('convocar faz POST /teams/:id/call-ups e devolve a lista de convocações criadas', () async {
      final fake = FakeApiClient(respostas: {
        '/teams/time-1/call-ups': [
          {
            'id': 'callup-1',
            'teamId': 'time-1',
            'matchId': null,
            'userId': 'user-1',
            'venueNameSnapshot': 'Arena Teste',
            'scheduledDate': '2026-09-10T00:00:00.000Z',
            'scheduledTime': '20:00',
            'status': 'PENDENTE',
            'respondedAt': null,
            'createdAt': '2026-08-21T03:08:27.908Z',
          },
        ],
      });
      final repo = TeamsRepository(fake);

      final callUps = await repo.convocar(
        'time-1',
        token,
        venueNameSnapshot: 'Arena Teste',
        scheduledDate: '2026-09-10',
        scheduledTime: '20:00',
      );

      expect(callUps, hasLength(1));
      expect(callUps.first.venueNameSnapshot, 'Arena Teste');
    });

    test('responderConvocacao envia o status certo em PATCH /call-ups/:id/respond', () async {
      final fake = FakeApiClient();
      final repo = TeamsRepository(fake);

      await repo.responderConvocacao('callup-1', token, status: 'CONFIRMADO');

      final chamada = fake.chamadas.single;
      expect(chamada.metodo, 'PATCH');
      expect(chamada.path, '/call-ups/callup-1/respond');
      expect(chamada.corpo, {'status': 'CONFIRMADO'});
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/perfil/perfil_repository.dart';

class FakeApiClient implements ApiClient {
  final List<String> chamadas = [];
  final Map<String, dynamic> respostas;
  FakeApiClient({this.respostas = const {}});

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async {
    chamadas.add(path);
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
}

void main() {
  const token = 'token-de-teste';

  test('meuPerfil faz GET /auth/me e devolve o MeuPerfil convertido', () async {
    final fake = FakeApiClient(respostas: {
      '/auth/me': {
        'id': 'user-1',
        'fullName': 'Jogador Teste',
        'email': 'jogador@teste.com',
        'avatarUrl': null,
        'city': null,
        'state': null,
        'dominantFoot': null,
        'bio': null,
        'modalidades': [],
        'estatisticas': {
          'jogosDisputados': 0,
          'gols': 0,
          'assistencias': 0,
          'cartoesAmarelos': 0,
          'cartoesVermelhos': 0,
          'mvp': 0,
          'convocacoes': 0,
        },
        'timesAtuais': [],
        'timesAnteriores': [],
      },
    });
    final repo = PerfilRepository(fake);

    final perfil = await repo.meuPerfil(token);

    expect(fake.chamadas.single, '/auth/me');
    expect(perfil.fullName, 'Jogador Teste');
  });

  test('perfilPublico faz GET /users/:id e devolve o MeuPerfil convertido, sem e-mail', () async {
    final fake = FakeApiClient(respostas: {
      '/users/user-2': {
        'id': 'user-2',
        'fullName': 'Outro Jogador',
        'avatarUrl': null,
        'city': null,
        'state': null,
        'dominantFoot': null,
        'bio': null,
        'modalidades': [],
        'estatisticas': {
          'jogosDisputados': 0,
          'gols': 0,
          'assistencias': 0,
          'cartoesAmarelos': 0,
          'cartoesVermelhos': 0,
          'mvp': 0,
          'convocacoes': 0,
        },
        'timesAtuais': [],
        'timesAnteriores': [],
      },
    });
    final repo = PerfilRepository(fake);

    final perfil = await repo.perfilPublico('user-2', token);

    expect(fake.chamadas.single, '/users/user-2');
    expect(perfil.fullName, 'Outro Jogador');
    expect(perfil.email, isNull);
  });
}

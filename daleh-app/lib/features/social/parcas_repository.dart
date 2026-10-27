import '../../core/api_client.dart';
import 'models/parca.dart';

class ParcasRepository {
  final ApiClient _api;
  ParcasRepository(this._api);

  Future<List<Parca>> seguindo(String token) async {
    final dados = await _api.getLista('/users/me/following', token: token);
    return dados.map((d) => Parca.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<List<Parca>> seguidores(String token) async {
    final dados = await _api.getLista('/users/me/followers', token: token);
    return dados.map((d) => Parca.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<void> seguir(String userId, String token) {
    return _api.postAutenticado('/users/$userId/follow', token: token);
  }

  Future<void> deixarDeSeguir(String userId, String token) {
    return _api.deleteAutenticado('/users/$userId/follow', token: token);
  }
}

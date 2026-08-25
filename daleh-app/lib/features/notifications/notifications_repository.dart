import '../../core/api_client.dart';
import 'models/app_notification.dart';

class NotificationsRepository {
  final ApiClient _api;
  NotificationsRepository(this._api);

  Future<List<AppNotification>> listarMinhas(String token) async {
    final lista = await _api.getLista('/notifications/mine', token: token);
    return lista.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> marcarLida(String id, String token) {
    return _api.patchAutenticado('/notifications/$id/read', token: token);
  }
}

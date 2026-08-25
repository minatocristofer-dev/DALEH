/// Espelha o Notification (`prisma/schema.prisma`): a coluna `payload` (json)
/// não tem `titulo`/`corpo` dedicados no schema — o backend grava esses dois
/// campos dentro do próprio `payload` (ver NotificationsService.notificar).
/// Se um dia aparecer um tipo de notificação sem titulo/corpo no payload,
/// caímos num texto genérico em vez de mostrar tela vazia/quebrada.
class AppNotification {
  final String id;
  final String type;
  final String titulo;
  final String corpo;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Payload cru vindo do backend (o mesmo `notifications.payload` do
  /// schema, sem `titulo`/`corpo`) — usado só pra resolver a navegação ao
  /// tocar na notificação (ver `notification_navigator.dart`).
  final Map<String, dynamic> payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.titulo,
    required this.corpo,
    required this.createdAt,
    required this.payload,
    this.readAt,
  });

  bool get lida => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      titulo: payload['titulo'] as String? ?? 'Notificação',
      corpo: payload['corpo'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      payload: payload,
    );
  }
}

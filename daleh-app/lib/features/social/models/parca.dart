/// Um "parça" na lista de seguindo/seguidores — só os dados pra um card
/// (ver `GET /users/me/following` e `/users/me/followers`).
class Parca {
  final String id;
  final String fullName;
  final String? nickname;
  final String? avatarUrl;

  Parca({required this.id, required this.fullName, this.nickname, this.avatarUrl});

  String get nomeExibido => (nickname != null && nickname!.trim().isNotEmpty) ? nickname! : fullName;

  factory Parca.fromJson(Map<String, dynamic> json) {
    return Parca(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Um "parça" na lista de seguindo/seguidores, ou um resultado de busca
/// (ver `GET /users/me/following`, `/users/me/followers` e `/users/search`).
/// `jaSegue` só vem preenchido de verdade pela busca — nas duas listas de
/// seguindo/seguidores o valor é óbvio pelo contexto (quem está na lista
/// "seguindo" já é seguido, por definição), então o backend não manda esse
/// campo ali e o default `false` nunca chega a ser mostrado.
class Parca {
  final String id;
  final String fullName;
  final String? nickname;
  final String? avatarUrl;
  final bool jaSegue;

  Parca({required this.id, required this.fullName, this.nickname, this.avatarUrl, this.jaSegue = false});

  String get nomeExibido => (nickname != null && nickname!.trim().isNotEmpty) ? nickname! : fullName;

  factory Parca.fromJson(Map<String, dynamic> json) {
    return Parca(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      jaSegue: json['jaSegue'] as bool? ?? false,
    );
  }
}

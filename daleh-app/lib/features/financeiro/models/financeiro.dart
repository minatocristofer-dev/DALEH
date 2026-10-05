class ItemCobranca {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final bool pago;
  final DateTime? pagoEm;

  const ItemCobranca({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.pago,
    required this.pagoEm,
  });

  factory ItemCobranca.fromJson(Map<String, dynamic> json) {
    return ItemCobranca(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      pago: json['pago'] as bool,
      pagoEm: json['pagoEm'] == null ? null : DateTime.parse(json['pagoEm'] as String),
    );
  }
}

class Cobranca {
  final String id;
  final String titulo;
  final double valor;
  final DateTime criadoEm;
  final List<ItemCobranca> itens;

  const Cobranca({
    required this.id,
    required this.titulo,
    required this.valor,
    required this.criadoEm,
    required this.itens,
  });

  int get quantidadePagos => itens.where((i) => i.pago).length;

  factory Cobranca.fromJson(Map<String, dynamic> json) {
    return Cobranca(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      valor: (json['valor'] as num).toDouble(),
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      itens: (json['itens'] as List<dynamic>)
          .map((i) => ItemCobranca.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CobrancasDoTime {
  final String? pixKey;
  final String? pixNome;
  final bool souGestor;
  final List<Cobranca> cobrancas;

  const CobrancasDoTime({
    required this.pixKey,
    required this.pixNome,
    required this.souGestor,
    required this.cobrancas,
  });

  factory CobrancasDoTime.fromJson(Map<String, dynamic> json) {
    return CobrancasDoTime(
      pixKey: json['pixKey'] as String?,
      pixNome: json['pixNome'] as String?,
      souGestor: json['souGestor'] as bool,
      cobrancas: (json['cobrancas'] as List<dynamic>)
          .map((c) => Cobranca.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Espelha o retorno de `GET /auth/me` (ver AuthService.me, Fase 6). Todos os
/// dados aqui são reais — nada de estatística inventada. Campos ausentes no
/// backend (overall, número da camisa, vitórias/derrotas) simplesmente não
/// existem neste model, porque o backend não os calcula (não há placar de
/// partida no schema).
class ModalidadeJogador {
  final String modalidade;
  final String label;
  final String posicaoPrincipal;
  final String? posicaoSecundaria;

  ModalidadeJogador({
    required this.modalidade,
    required this.label,
    required this.posicaoPrincipal,
    this.posicaoSecundaria,
  });

  factory ModalidadeJogador.fromJson(Map<String, dynamic> json) {
    return ModalidadeJogador(
      modalidade: json['modalidade'] as String,
      label: json['label'] as String,
      posicaoPrincipal: json['posicaoPrincipal'] as String,
      posicaoSecundaria: json['posicaoSecundaria'] as String?,
    );
  }
}

class EstatisticasJogador {
  final int jogosDisputados;
  final int gols;
  final int assistencias;
  final int cartoesAmarelos;
  final int cartoesVermelhos;
  final int mvp;
  final int convocacoes;

  EstatisticasJogador({
    required this.jogosDisputados,
    required this.gols,
    required this.assistencias,
    required this.cartoesAmarelos,
    required this.cartoesVermelhos,
    required this.mvp,
    required this.convocacoes,
  });

  factory EstatisticasJogador.fromJson(Map<String, dynamic> json) {
    int lerInt(String chave) => (json[chave] as num?)?.toInt() ?? 0;
    return EstatisticasJogador(
      jogosDisputados: lerInt('jogosDisputados'),
      gols: lerInt('gols'),
      assistencias: lerInt('assistencias'),
      cartoesAmarelos: lerInt('cartoesAmarelos'),
      cartoesVermelhos: lerInt('cartoesVermelhos'),
      mvp: lerInt('mvp'),
      convocacoes: lerInt('convocacoes'),
    );
  }
}

class TimeResumo {
  final String id;
  final String name;
  final String? crestUrl;
  final String? papel;

  TimeResumo({required this.id, required this.name, this.crestUrl, this.papel});

  factory TimeResumo.fromJson(Map<String, dynamic> json) {
    return TimeResumo(
      id: json['id'] as String,
      name: json['name'] as String,
      crestUrl: json['crestUrl'] as String?,
      papel: json['papel'] as String?,
    );
  }
}

class MeuPerfil {
  final String id;
  final String fullName;
  // Nulo quando o perfil vem de `GET /users/:id` (perfil público, Fase 7) —
  // esse endpoint nunca devolve e-mail, por privacidade. Só vem preenchido
  // em `GET /auth/me` (o próprio usuário).
  final String? email;
  final String? avatarUrl;
  final String? city;
  final String? state;
  final String? dominantFoot;
  final String? bio;
  // Calculada pelo backend a partir de `birthDate` (Fase 9) — nunca um
  // número fixo, então acompanha o aniversário do jogador sozinha. Fica
  // nula pra praticamente todo mundo hoje: nenhum fluxo de cadastro/edição
  // de perfil ainda coleta data de nascimento (isso é uma lacuna conhecida,
  // não corrigida nesta fase — o campo já existe no backend, só falta uma
  // forma de preenchê-lo).
  final int? idade;
  final List<ModalidadeJogador> modalidades;
  final EstatisticasJogador estatisticas;
  final List<TimeResumo> timesAtuais;
  final List<TimeResumo> timesAnteriores;

  MeuPerfil({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.city,
    this.state,
    this.dominantFoot,
    this.bio,
    this.idade,
    required this.modalidades,
    required this.estatisticas,
    required this.timesAtuais,
    required this.timesAnteriores,
  });

  /// Posição de destaque do card — quando o jogador tem mais de uma
  /// modalidade cadastrada, usamos a primeira só como escolha de exibição
  /// (não existe conceito de "modalidade principal" no backend).
  ModalidadeJogador? get modalidadePrincipal => modalidades.isEmpty ? null : modalidades.first;

  factory MeuPerfil.fromJson(Map<String, dynamic> json) {
    final modalidadesJson = json['modalidades'] as List? ?? [];
    final timesAtuaisJson = json['timesAtuais'] as List? ?? [];
    final timesAnterioresJson = json['timesAnteriores'] as List? ?? [];
    return MeuPerfil(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      dominantFoot: json['dominantFoot'] as String?,
      bio: json['bio'] as String?,
      idade: json['idade'] as int?,
      modalidades: modalidadesJson.map((m) => ModalidadeJogador.fromJson(m as Map<String, dynamic>)).toList(),
      estatisticas: EstatisticasJogador.fromJson(json['estatisticas'] as Map<String, dynamic>? ?? {}),
      timesAtuais: timesAtuaisJson.map((t) => TimeResumo.fromJson(t as Map<String, dynamic>)).toList(),
      timesAnteriores: timesAnterioresJson.map((t) => TimeResumo.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

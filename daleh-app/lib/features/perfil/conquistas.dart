import 'package:flutter/material.dart';
import 'models/meu_perfil.dart';

/// Conquistas do DALEH — "Fase 1" (QA de 2026-09-24, escopo definido pelo
/// usuário). Mesmo princípio das estatísticas do resto do app: NUNCA
/// guardadas em nenhuma tabela, sempre recalculadas na hora a partir dos
/// números reais já existentes em `EstatisticasJogador` (que por sua vez já
/// vêm de `MatchEvent`/`MatchAttendance` reais). Não existe "conquista
/// desbloqueada em tal data" — existe só "bate o número, tá desbloqueada
/// agora"; se um gol for removido de uma súmula, a conquista some sozinha,
/// do mesmo jeito que o contador de gols também mudaria.
///
/// Planejado (não implementado ainda, decisão explícita do usuário): depois
/// do lançamento, essa seção vai ficar restrita a assinantes — o schema já
/// tem `User.isPro`/`proExpiresAt` prontos pra isso, só falta o gate.
class Conquista {
  final String chave;
  final String nome;
  final String descricao;
  final IconData icone;
  final bool desbloqueada;

  const Conquista({
    required this.chave,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.desbloqueada,
  });
}

List<Conquista> calcularConquistas(EstatisticasJogador e) {
  final participacoesEmGol = e.gols + e.assistencias;

  return [
    Conquista(
      chave: 'artilheiro',
      nome: 'Artilheiro',
      descricao: '10 gols marcados',
      icone: Icons.sports_soccer,
      desbloqueada: e.gols >= 10,
    ),
    Conquista(
      chave: 'garcom',
      nome: 'Garçom',
      descricao: '10 assistências',
      icone: Icons.room_service_outlined,
      desbloqueada: e.assistencias >= 10,
    ),
    Conquista(
      chave: 'estrela_da_partida',
      nome: 'Estrela da Partida',
      descricao: '5 vezes eleito MVP',
      icone: Icons.star,
      desbloqueada: e.mvp >= 5,
    ),
    Conquista(
      chave: 'presenca_de_ferro',
      nome: 'Presença de Ferro',
      descricao: '20 jogos disputados',
      icone: Icons.shield,
      desbloqueada: e.jogosDisputados >= 20,
    ),
    Conquista(
      chave: 'camisa_10',
      nome: 'Camisa 10',
      descricao: '15 participações em gol (gols + assistências)',
      icone: Icons.checkroom,
      desbloqueada: participacoesEmGol >= 15,
    ),
  ];
}

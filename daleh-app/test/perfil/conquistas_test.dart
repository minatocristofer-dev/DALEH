import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/conquistas.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';

EstatisticasJogador _stats({
  int jogosDisputados = 0,
  int gols = 0,
  int assistencias = 0,
  int mvp = 0,
}) {
  return EstatisticasJogador(
    jogosDisputados: jogosDisputados,
    gols: gols,
    assistencias: assistencias,
    cartoesAmarelos: 0,
    cartoesVermelhos: 0,
    mvp: mvp,
    convocacoes: 0,
  );
}

void main() {
  test('jogador zerado (novato) não desbloqueia nenhuma conquista', () {
    final conquistas = calcularConquistas(_stats());

    expect(conquistas, hasLength(5));
    expect(conquistas.every((c) => !c.desbloqueada), isTrue);
  });

  test('5 chaves fixas, sempre na mesma ordem — nada duplicado nem faltando', () {
    final chaves = calcularConquistas(_stats()).map((c) => c.chave).toList();
    expect(chaves, ['artilheiro', 'garcom', 'estrela_da_partida', 'presenca_de_ferro', 'camisa_10']);
  });

  group('Artilheiro — 10 gols', () {
    test('9 gols ainda não desbloqueia', () {
      final c = calcularConquistas(_stats(gols: 9)).firstWhere((c) => c.chave == 'artilheiro');
      expect(c.desbloqueada, isFalse);
    });
    test('10 gols desbloqueia', () {
      final c = calcularConquistas(_stats(gols: 10)).firstWhere((c) => c.chave == 'artilheiro');
      expect(c.desbloqueada, isTrue);
    });
  });

  group('Garçom — 10 assistências', () {
    test('9 assistências ainda não desbloqueia', () {
      final c = calcularConquistas(_stats(assistencias: 9)).firstWhere((c) => c.chave == 'garcom');
      expect(c.desbloqueada, isFalse);
    });
    test('10 assistências desbloqueia', () {
      final c = calcularConquistas(_stats(assistencias: 10)).firstWhere((c) => c.chave == 'garcom');
      expect(c.desbloqueada, isTrue);
    });
  });

  group('Estrela da Partida — 5 MVPs', () {
    test('4 MVPs ainda não desbloqueia', () {
      final c = calcularConquistas(_stats(mvp: 4)).firstWhere((c) => c.chave == 'estrela_da_partida');
      expect(c.desbloqueada, isFalse);
    });
    test('5 MVPs desbloqueia', () {
      final c = calcularConquistas(_stats(mvp: 5)).firstWhere((c) => c.chave == 'estrela_da_partida');
      expect(c.desbloqueada, isTrue);
    });
  });

  group('Presença de Ferro — 20 jogos', () {
    test('19 jogos ainda não desbloqueia', () {
      final c = calcularConquistas(_stats(jogosDisputados: 19)).firstWhere((c) => c.chave == 'presenca_de_ferro');
      expect(c.desbloqueada, isFalse);
    });
    test('20 jogos desbloqueia', () {
      final c = calcularConquistas(_stats(jogosDisputados: 20)).firstWhere((c) => c.chave == 'presenca_de_ferro');
      expect(c.desbloqueada, isTrue);
    });
  });

  group('Camisa 10 — 15 participações em gol (gols + assistências)', () {
    test('14 participações (ex: 7 gols + 7 assistências) ainda não desbloqueia', () {
      final c = calcularConquistas(_stats(gols: 7, assistencias: 7)).firstWhere((c) => c.chave == 'camisa_10');
      expect(c.desbloqueada, isFalse);
    });
    test('15 participações (ex: 10 gols + 5 assistências) desbloqueia — soma dos dois, não cada um sozinho', () {
      final c = calcularConquistas(_stats(gols: 10, assistencias: 5)).firstWhere((c) => c.chave == 'camisa_10');
      expect(c.desbloqueada, isTrue);
    });
    test('15 assistências sozinhas (sem gol nenhum) também contam pra soma', () {
      final c = calcularConquistas(_stats(gols: 0, assistencias: 15)).firstWhere((c) => c.chave == 'camisa_10');
      expect(c.desbloqueada, isTrue);
    });
  });

  test('jogador completo bate todos os números ao mesmo tempo — as 5 desbloqueiam juntas', () {
    final conquistas = calcularConquistas(_stats(jogosDisputados: 25, gols: 12, assistencias: 11, mvp: 6));
    expect(conquistas.every((c) => c.desbloqueada), isTrue);
  });
}

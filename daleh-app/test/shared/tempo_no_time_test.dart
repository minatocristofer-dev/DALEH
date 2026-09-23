import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/shared/tempo_no_time.dart';

void main() {
  // `agora` fixo em todos os testes — sem isso o teste ficaria dependente
  // do dia em que roda (frágil, quebraria sozinho meses depois).
  final agora = DateTime(2026, 9, 22);

  test('menos de 1 mês — "Novo no time"', () {
    expect(tempoNoTime(DateTime(2026, 9, 5), agora: agora), 'Novo no time');
  });

  test('exatamente hoje — "Novo no time" (nunca "há 0 meses")', () {
    expect(tempoNoTime(agora, agora: agora), 'Novo no time');
  });

  test('1 mês completo', () {
    expect(tempoNoTime(DateTime(2026, 8, 22), agora: agora), 'Há 1 mês no time');
  });

  test('3 meses', () {
    expect(tempoNoTime(DateTime(2026, 6, 22), agora: agora), 'Há 3 meses no time');
  });

  test('11 meses — ainda em meses, não vira "quase 1 ano"', () {
    expect(tempoNoTime(DateTime(2025, 10, 22), agora: agora), 'Há 11 meses no time');
  });

  test('exatamente 1 ano', () {
    expect(tempoNoTime(DateTime(2025, 9, 22), agora: agora), 'Há 1 ano no time');
  });

  test('1 ano e 1 mês', () {
    expect(tempoNoTime(DateTime(2025, 8, 22), agora: agora), 'Há 1 ano e 1 mês no time');
  });

  test('2 anos exatos', () {
    expect(tempoNoTime(DateTime(2024, 9, 22), agora: agora), 'Há 2 anos no time');
  });

  test('2 anos e 3 meses', () {
    expect(tempoNoTime(DateTime(2024, 6, 22), agora: agora), 'Há 2 anos e 3 meses no time');
  });

  test('dia do mês ainda não chegou — não conta o mês corrente como completo', () {
    // Entrou dia 25/ago, hoje é 22/set: ainda faltam 3 dias pra completar
    // 1 mês de casa — continua "Novo no time", não "Há 1 mês".
    expect(tempoNoTime(DateTime(2026, 8, 25), agora: agora), 'Novo no time');
  });
}

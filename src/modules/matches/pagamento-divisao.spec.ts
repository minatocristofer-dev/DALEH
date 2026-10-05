import { calcularDivisaoPagamento } from './pagamento-divisao';

describe('calcularDivisaoPagamento', () => {
  const jogadores = (quantidadeCasa: number, quantidadeFora: number) => [
    ...Array.from({ length: quantidadeCasa }, (_, i) => ({ userId: `c${i}`, teamId: 'casa' })),
    ...Array.from({ length: quantidadeFora }, (_, i) => ({ userId: `f${i}`, teamId: 'fora' })),
  ];

  it('sem valor da quadra, ninguém tem valor devido', () => {
    const r = calcularDivisaoPagamento(null, jogadores(2, 2), 'casa', 'fora');
    expect([...r.valorDevido.values()].every((v) => v === null)).toBe(true);
    expect(r.porTime.home).toBeNull();
  });

  it('partida com times: 50% pra cada time, dividido entre os jogadores do time', () => {
    const r = calcularDivisaoPagamento(200, jogadores(5, 4), 'casa', 'fora');

    expect(r.porTime.home).toEqual({ valorTime: 100, valorPorJogador: 20, jogadores: 5 });
    expect(r.porTime.away).toEqual({ valorTime: 100, valorPorJogador: 25, jogadores: 4 });
    expect(r.valorDevido.get('c0')).toBe(20);
    expect(r.valorDevido.get('f0')).toBe(25);
  });

  it('a soma dos jogadores fecha com o total (quando a divisão é exata)', () => {
    const r = calcularDivisaoPagamento(180, jogadores(3, 3), 'casa', 'fora');
    const soma = [...r.valorDevido.values()].reduce<number>((acc, v) => acc + (v ?? 0), 0);
    expect(soma).toBe(180);
  });

  it('arredonda pra centavos em divisões não exatas', () => {
    const r = calcularDivisaoPagamento(100, jogadores(3, 3), 'casa', 'fora');
    expect(r.valorDevido.get('c0')).toBe(16.67);
  });

  it('jogador confirmado sem time determinado fica com valor nulo, sem entrar na conta', () => {
    const confirmados = [...jogadores(2, 2), { userId: 'solto', teamId: null }];
    const r = calcularDivisaoPagamento(100, confirmados, 'casa', 'fora');

    expect(r.valorDevido.get('solto')).toBeNull();
    expect(r.porTime.home?.jogadores).toBe(2);
    expect(r.porTime.home?.valorPorJogador).toBe(25);
  });

  it('time sem nenhum jogador confirmado não gera valor por jogador', () => {
    const r = calcularDivisaoPagamento(100, jogadores(2, 0), 'casa', 'fora');
    expect(r.porTime.away).toEqual({ valorTime: 50, valorPorJogador: null, jogadores: 0 });
    expect(r.valorDevido.get('c0')).toBe(25);
  });

  it('partida avulsa (sem times): divide igual entre todos os confirmados', () => {
    const confirmados = [{ userId: 'a' }, { userId: 'b' }, { userId: 'c' }, { userId: 'd' }];
    const r = calcularDivisaoPagamento(100, confirmados, null, null);

    expect(r.valorPorJogadorAvulsa).toBe(25);
    expect(r.valorDevido.get('a')).toBe(25);
    expect(r.porTime.home).toBeNull();
  });

  it('sem confirmados não quebra', () => {
    const r = calcularDivisaoPagamento(100, [], null, null);
    expect(r.valorPorJogadorAvulsa).toBeNull();
    expect(r.valorDevido.size).toBe(0);
  });
});

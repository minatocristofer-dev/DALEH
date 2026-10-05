export interface ParticipantePagamento {
  userId: string;
  teamId?: string | null;
}

export interface DivisaoPagamento {
  valorDevido: Map<string, number | null>;
  porTime: { home: TotalTime | null; away: TotalTime | null };
  valorPorJogadorAvulsa: number | null;
}

export interface TotalTime {
  valorTime: number;
  valorPorJogador: number | null;
  jogadores: number;
}

const centavos = (v: number) => Math.round(v * 100) / 100;

/**
 * Divisão do valor da quadra entre os confirmados.
 * - Partida com dois times: 50% pra cada time; dentro do time, divide igual
 *   entre os jogadores confirmados daquele time. Confirmado sem time
 *   determinado fica com valor nulo (não inventamos a qual metade pertence).
 * - Partida avulsa (sem times): divide igual entre todos os confirmados.
 * Arredonda pra centavos, então a soma pode diferir do total em até poucos
 * centavos — é o comportamento esperado de uma divisão em reais.
 */
export function calcularDivisaoPagamento(
  valorQuadra: number | null,
  confirmados: ParticipantePagamento[],
  homeTeamId: string | null,
  awayTeamId: string | null,
): DivisaoPagamento {
  const valorDevido = new Map<string, number | null>();
  const temTimes = !!(homeTeamId && awayTeamId);

  if (valorQuadra == null) {
    confirmados.forEach((p) => valorDevido.set(p.userId, null));
    return {
      valorDevido,
      porTime: { home: null, away: null },
      valorPorJogadorAvulsa: null,
    };
  }

  if (!temTimes) {
    const por = confirmados.length ? centavos(valorQuadra / confirmados.length) : null;
    confirmados.forEach((p) => valorDevido.set(p.userId, por));
    return {
      valorDevido,
      porTime: { home: null, away: null },
      valorPorJogadorAvulsa: por,
    };
  }

  const metade = valorQuadra / 2;
  const totalDoTime = (teamId: string): TotalTime => {
    const membros = confirmados.filter((p) => p.teamId === teamId);
    const porJogador = membros.length ? centavos(metade / membros.length) : null;
    membros.forEach((p) => valorDevido.set(p.userId, porJogador));
    return { valorTime: centavos(metade), valorPorJogador: porJogador, jogadores: membros.length };
  };

  const home = totalDoTime(homeTeamId!);
  const away = totalDoTime(awayTeamId!);
  confirmados
    .filter((p) => p.teamId !== homeTeamId && p.teamId !== awayTeamId)
    .forEach((p) => valorDevido.set(p.userId, null));

  return { valorDevido, porTime: { home, away }, valorPorJogadorAvulsa: null };
}

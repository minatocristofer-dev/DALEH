/**
 * Fase 9 — backfill único de MatchEvent.teamId pros eventos criados ANTES
 * dessa coluna existir.
 *
 * Só mexe em eventos tipo 'goal'/'assist' com teamId nulo. Determina o time
 * usando o único dado disponível pra isso retroativamente: o TeamMember
 * ATIVO do jogador nos dois times da partida no momento em que este script
 * roda — a mesma fonte, por sinal, que o cálculo de placar usava antes desta
 * fase (e que a Fase 9 elimina para eventos NOVOS, que passam a congelar o
 * time no momento do gol). Pra eventos antigos não existe outra fonte.
 *
 * Se não for possível determinar com segurança (partida sem os dois times,
 * ou jogador que não é membro ativo de nenhum dos dois hoje), o evento é
 * deixado com teamId nulo — não inventamos um valor. Esses casos ficam
 * documentados na saída do script.
 *
 * Idempotente: só processa `WHERE team_id IS NULL`, seguro rodar de novo.
 */
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const eventosSemTime = await prisma.matchEvent.findMany({
    where: { teamId: null, eventType: { in: ['goal', 'assist'] } },
    include: { match: { select: { id: true, homeTeamId: true, awayTeamId: true } } },
  });

  console.log(`Eventos gol/assistência sem teamId encontrados: ${eventosSemTime.length}`);

  let atualizados = 0;
  let semTimesNaPartida = 0;
  let naoDeterminaveis = 0;

  for (const evento of eventosSemTime) {
    const { homeTeamId, awayTeamId } = evento.match;
    if (!homeTeamId || !awayTeamId) {
      console.log(`  evento ${evento.id}: partida ${evento.matchId} não tem os dois times (avulsa) — deixado sem teamId.`);
      semTimesNaPartida++;
      continue;
    }

    const membro = await prisma.teamMember.findFirst({
      where: { userId: evento.userId, status: 'active', teamId: { in: [homeTeamId, awayTeamId] } },
      select: { teamId: true },
    });

    if (!membro) {
      console.log(
        `  evento ${evento.id} (userId ${evento.userId}, partida ${evento.matchId}): jogador não é membro ativo de nenhum dos dois times HOJE — não determinável com segurança, deixado sem teamId.`,
      );
      naoDeterminaveis++;
      continue;
    }

    await prisma.matchEvent.update({ where: { id: evento.id }, data: { teamId: membro.teamId } });
    console.log(`  evento ${evento.id} (userId ${evento.userId}): teamId definido como ${membro.teamId}.`);
    atualizados++;
  }

  console.log('\nResumo:');
  console.log(`  atualizados com sucesso: ${atualizados}`);
  console.log(`  ignorados (partida avulsa, sem times): ${semTimesNaPartida}`);
  console.log(`  ignorados (jogador não determinável): ${naoDeterminaveis}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

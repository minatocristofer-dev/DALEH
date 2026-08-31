import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateMatchDto } from './dto/create-match.dto';
import { UpdateMatchStatusDto } from './dto/update-match-status.dto';
import { CreateEventDto } from './dto/create-event.dto';
import { RegisterGoalDto } from './dto/register-goal.dto';
import { ElectMvpDto } from './dto/elect-mvp.dto';

const STATUS_QUE_BLOQUEIA_NOVOS_EVENTOS = ['finished', 'cancelled'];

@Injectable()
export class MatchesService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    private teamAuth: TeamAuthorizationService,
  ) {}

  async criarPartida(userId: string, dto: CreateMatchDto) {
    const modalidade = await this.prisma.modalidade.findUnique({ where: { key: dto.modalidade } });
    if (!modalidade) throw new BadRequestException('Modalidade inválida.');

    return this.prisma.match.create({
      data: {
        createdById: userId,
        venueId: dto.venueId,
        modalidadeId: modalidade.id,
        scheduledAt: new Date(dto.scheduledAt),
        maxPlayers: dto.maxPlayers,
        visibility: dto.visibility ?? 'public',
      },
    });
  }

  listarPartidas(status?: string) {
    return this.prisma.match.findMany({
      where: { visibility: 'public', ...(status ? { status } : {}) },
      include: {
        modalidade: true,
        venue: true,
        homeTeam: { select: { id: true, name: true, crestUrl: true } },
        awayTeam: { select: { id: true, name: true, crestUrl: true } },
        _count: { select: { attendance: true } },
      },
      orderBy: { scheduledAt: 'asc' },
    });
  }

  async obterPartida(id: string, userId?: string) {
    const partida = await this.prisma.match.findUnique({
      where: { id },
      include: {
        modalidade: true,
        venue: true,
        homeTeam: { select: { id: true, name: true, crestUrl: true } },
        awayTeam: { select: { id: true, name: true, crestUrl: true } },
        attendance: { include: { user: { select: { id: true, fullName: true, avatarUrl: true } } } },
        events: { include: { user: { select: { id: true, fullName: true, avatarUrl: true } } } },
      },
    });
    if (!partida) throw new NotFoundException('Partida não encontrada.');

    if (partida.visibility === 'private') {
      await this.exigirAcessoPartidaPrivada(partida, userId);
    }

    // Súmula digital (Fase 8) — placar e permissão de gestão são calculados
    // aqui, nunca guardados em coluna própria em `Match` (a fonte de verdade
    // continua sendo a contagem de MatchEvent do tipo 'goal').
    const temTimes = !!(partida.homeTeamId && partida.awayTeamId);
    const { homeScore, awayScore } = temTimes
      ? this.calcularPlacar(partida.homeTeamId!, partida.awayTeamId!, partida.events)
      : { homeScore: null, awayScore: null };

    let souGestorDaSumula = false;
    if (userId) {
      souGestorDaSumula = temTimes
        ? await this.souGestorDeUmDosTimes(partida.homeTeamId!, partida.awayTeamId!, userId)
        : partida.createdById === userId;
    }

    const attendance = temTimes
      ? await this.comEscalacao(partida.homeTeamId!, partida.awayTeamId!, partida.modalidadeId, partida.attendance ?? [])
      : partida.attendance;

    return { ...partida, attendance, homeScore, awayScore, souGestorDaSumula };
  }

  // Escalação: pra cada participante, resolve de qual time (casa/fora) ele é
  // membro ATIVO hoje e sua posição principal cadastrada pra modalidade
  // desta partida — dado lido em tempo real (diferente do MatchEvent.teamId
  // usado no placar, que é congelado; aqui é só "quem tá no time agora",
  // não precisa da mesma estabilidade histórica). Quem não é membro ativo de
  // nenhum dos dois times, ou não tem posição cadastrada pra essa
  // modalidade, fica com o campo null — nunca inventamos um valor.
  private async comEscalacao<T extends { userId: string }>(
    homeTeamId: string,
    awayTeamId: string,
    modalidadeId: string,
    attendance: T[],
  ) {
    const userIds = attendance.map((a) => a.userId);
    const [membros, posicoes] = await Promise.all([
      this.prisma.teamMember.findMany({
        where: { status: 'active', teamId: { in: [homeTeamId, awayTeamId] }, userId: { in: userIds } },
        select: { userId: true, teamId: true },
      }),
      this.prisma.playerModalidade.findMany({
        where: { modalidadeId, userId: { in: userIds } },
        select: { userId: true, posicaoPrincipal: true },
      }),
    ]);
    const timePorJogador = new Map(membros.map((m) => [m.userId, m.teamId]));
    const posicaoPorJogador = new Map(posicoes.map((p) => [p.userId, p.posicaoPrincipal]));

    return attendance.map((a) => ({
      ...a,
      teamId: timePorJogador.get(a.userId) ?? null,
      posicaoPrincipal: posicaoPorJogador.get(a.userId) ?? null,
    }));
  }

  // Deriva de qual time (retorna o próprio teamId) um jogador faz parte,
  // usando a relação TeamMember já existente — nenhuma "escalação paralela"
  // foi criada. Só considera vínculo ativo; quem não é membro ativo de
  // nenhum dos dois times não tem time determinável (devolve null).
  private async timeDoJogador(homeTeamId: string, awayTeamId: string, userId: string): Promise<string | null> {
    const membro = await this.prisma.teamMember.findFirst({
      where: { userId, status: 'active', teamId: { in: [homeTeamId, awayTeamId] } },
      select: { teamId: true },
    });
    return membro?.teamId ?? null;
  }

  // Placar = contagem de MatchEvent tipo 'goal', usando o `teamId` CONGELADO
  // em cada evento no momento em que ele foi criado (Fase 9) — nunca mais
  // consultando o TeamMember atual. É exatamente isso que garante que o
  // placar de uma partida já finalizada não muda se o jogador sair do time
  // depois. Eventos antigos sem `teamId` (de antes desta fase, não
  // determináveis com segurança na migração) simplesmente não são
  // contabilizados em nenhum dos dois lados — não inventamos a atribuição.
  private calcularPlacar(
    homeTeamId: string,
    awayTeamId: string,
    eventos: { teamId: string | null; eventType: string }[],
  ): { homeScore: number; awayScore: number } {
    let homeScore = 0;
    let awayScore = 0;
    for (const evento of eventos) {
      if (evento.eventType !== 'goal') continue;
      if (evento.teamId === homeTeamId) homeScore++;
      else if (evento.teamId === awayTeamId) awayScore++;
    }
    return { homeScore, awayScore };
  }

  // Versão booleana (não lança) de "é capitão/dono de um dos dois times" —
  // reaproveita o mesmo `TeamAuthorizationService.exigirCapitaoOuDono` usado
  // pra autorizar de verdade, então não existe risco de a checagem de
  // exibição (esse método) divergir da checagem de autorização real.
  private async souGestorDeUmDosTimes(homeTeamId: string, awayTeamId: string, userId: string): Promise<boolean> {
    try {
      await this.teamAuth.exigirCapitaoOuDono(homeTeamId, userId);
      return true;
    } catch {
      try {
        await this.teamAuth.exigirCapitaoOuDono(awayTeamId, userId);
        return true;
      } catch {
        return false;
      }
    }
  }

  // Autorização de verdade (lança 403) — capitão/dono de QUALQUER um dos
  // dois times participantes pode alimentar a súmula, não só do seu próprio
  // time (ver Fase 8, seção 6 do prompt).
  private async exigirGestorDeUmDosTimes(homeTeamId: string, awayTeamId: string, userId: string) {
    try {
      await this.teamAuth.exigirCapitaoOuDono(homeTeamId, userId);
      return;
    } catch {
      // Se também falhar aqui, a exceção do segundo time propaga — é ela
      // que o chamador recebe.
      await this.teamAuth.exigirCapitaoOuDono(awayTeamId, userId);
    }
  }

  // Registrar gol (Fase 8) — só pra partidas com os dois times vinculados
  // (nasce de um TeamChallenge aceito). Placar nunca é recebido do cliente:
  // é sempre recalculado a partir dos MatchEvent tipo 'goal' já existentes.
  async registrarGol(matchId: string, userId: string, dto: RegisterGoalDto) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Partida não encontrada.');
    if (!match.homeTeamId || !match.awayTeamId) {
      throw new BadRequestException(
        'Essa partida não tem os dois times vinculados — não é possível registrar gol com placar por time.',
      );
    }
    if (STATUS_QUE_BLOQUEIA_NOVOS_EVENTOS.includes(match.status)) {
      throw new BadRequestException('Essa partida já foi encerrada — não é possível registrar novos eventos.');
    }

    await this.exigirGestorDeUmDosTimes(match.homeTeamId, match.awayTeamId, userId);

    const timeDoGoleador = await this.timeDoJogador(match.homeTeamId, match.awayTeamId, dto.scorerId);
    if (!timeDoGoleador) {
      throw new BadRequestException('O jogador escolhido não pertence a nenhum dos times desta partida.');
    }
    const presencaGoleador = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId: dto.scorerId } },
    });
    if (!presencaGoleador || presencaGoleador.status !== 'confirmed') {
      throw new BadRequestException('O jogador escolhido não confirmou presença nessa partida.');
    }

    if (dto.assistId) {
      if (dto.assistId === dto.scorerId) {
        throw new BadRequestException('A assistência não pode ser do mesmo jogador que fez o gol.');
      }
      const timeDoAssistente = await this.timeDoJogador(match.homeTeamId, match.awayTeamId, dto.assistId);
      if (!timeDoAssistente) {
        throw new BadRequestException('O jogador escolhido pra assistência não pertence a nenhum dos times desta partida.');
      }
      const presencaAssistente = await this.prisma.matchAttendance.findUnique({
        where: { matchId_userId: { matchId, userId: dto.assistId } },
      });
      if (!presencaAssistente || presencaAssistente.status !== 'confirmed') {
        throw new BadRequestException('O jogador escolhido pra assistência não confirmou presença nessa partida.');
      }
      if (timeDoAssistente !== timeDoGoleador) {
        throw new BadRequestException('A assistência precisa ser de um jogador do mesmo time do goleador.');
      }
    }

    // teamDoGoleador/teamDoAssistente (calculados acima, uma única vez) são
    // gravados junto com o evento — congelam o time pra sempre, em vez de
    // recalcular a partir do TeamMember atual toda vez que o placar for lido.
    const [gol, assistencia] = await this.prisma.$transaction(async (tx) => {
      const golCriado = await tx.matchEvent.create({
        data: { matchId, userId: dto.scorerId, teamId: timeDoGoleador, eventType: 'goal', minute: dto.minute },
      });
      const assistenciaCriada = dto.assistId
        ? await tx.matchEvent.create({
            data: { matchId, userId: dto.assistId, teamId: timeDoGoleador, eventType: 'assist', minute: dto.minute },
          })
        : null;
      return [golCriado, assistenciaCriada];
    });

    return { gol, assistencia };
  }

  // Eleição de MVP (Fase 8) — só depois da partida finalizada, único por
  // partida (reaproveita MatchEvent tipo 'mvp', já existente — nenhuma
  // tabela nova). Em partida sem os dois times (avulsa), não existe conceito
  // de "capitão" pra autorizar — cai de volta pro criador, mesma regra que
  // já existia pra outras ações administrativas da partida avulsa.
  async elegerMvp(matchId: string, userId: string, dto: ElectMvpDto) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Partida não encontrada.');
    if (match.status !== 'finished') {
      throw new BadRequestException('O MVP só pode ser eleito depois que a partida for finalizada.');
    }

    if (match.homeTeamId && match.awayTeamId) {
      await this.exigirGestorDeUmDosTimes(match.homeTeamId, match.awayTeamId, userId);
    } else {
      await this.exigirCriador(matchId, userId);
    }

    const presenca = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId: dto.userId } },
    });
    if (!presenca || presenca.status !== 'confirmed') {
      throw new BadRequestException('O MVP precisa ser um jogador que participou dessa partida.');
    }

    // Checagem rápida (caminho comum, sem corrida real) — dá um erro
    // amigável na grande maioria dos casos sem precisar tentar o insert.
    const mvpExistente = await this.prisma.matchEvent.findFirst({ where: { matchId, eventType: 'mvp' } });
    if (mvpExistente) {
      throw new ConflictException('O MVP dessa partida já foi eleito.');
    }

    // Trava de verdade contra corrida (Fase 9): usar um `id` determinístico
    // (em vez do uuid aleatório padrão) faz a PRIMARY KEY do Postgres
    // rejeitar atomicamente uma segunda eleição simultânea — sem isso, duas
    // requisições quase ao mesmo tempo poderiam passar as duas pelo
    // `findFirst` acima antes de qualquer uma criar o evento.
    try {
      return await this.prisma.matchEvent.create({
        data: { id: `mvp-${matchId}`, matchId, userId: dto.userId, eventType: 'mvp' },
      });
    } catch (erro) {
      if (erro instanceof Prisma.PrismaClientKnownRequestError && erro.code === 'P2002') {
        throw new ConflictException('O MVP dessa partida já foi eleito.');
      }
      throw erro;
    }
  }

  // Partida PRIVATE só pode ser vista por quem já está envolvido nela —
  // criador, participante (attendance), convocado (call-up) ou membro de um
  // dos times que estão jogando. Conhecer o ID sozinho não basta.
  private async exigirAcessoPartidaPrivada(
    partida: { id: string; createdById: string; homeTeamId: string | null; awayTeamId: string | null },
    userId: string | undefined,
  ) {
    if (!userId) throw new ForbiddenException('Essa partida é privada.');
    if (partida.createdById === userId) return;

    const participante = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId: partida.id, userId } },
    });
    if (participante) return;

    const convocado = await this.prisma.callUp.findFirst({ where: { matchId: partida.id, userId } });
    if (convocado) return;

    const timesDaPartida = [partida.homeTeamId, partida.awayTeamId].filter((v): v is string => !!v);
    if (timesDaPartida.length > 0) {
      const membroDoTime = await this.prisma.teamMember.findFirst({
        where: { userId, status: 'active', teamId: { in: timesDaPartida } },
      });
      if (membroDoTime) return;
    }

    throw new ForbiddenException('Essa partida é privada.');
  }

  // `finished` e `cancelled` são estados terminais (Fase 9) — depois deles,
  // nenhuma alteração de status é aceita, em nenhuma direção. Antes disso, o
  // fluxo livre entre scheduled/in_progress/cancelled/finished continua
  // exatamente como já funcionava (nenhuma máquina de estados nova foi
  // imposta pros estados não-terminais, só a trava de não sair deles).
  async atualizarStatus(id: string, userId: string, dto: UpdateMatchStatusDto) {
    const match = await this.exigirCriador(id, userId);
    if (STATUS_QUE_BLOQUEIA_NOVOS_EVENTOS.includes(match.status)) {
      throw new BadRequestException('Essa partida já foi encerrada — o status não pode mais ser alterado.');
    }
    return this.prisma.match.update({ where: { id }, data: { status: dto.status } });
  }

  async confirmarPresenca(matchId: string, userId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Partida não encontrada.');

    const existente = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId } },
    });
    if (existente && existente.status !== 'declined') {
      throw new ConflictException('Você já confirmou presença nessa partida.');
    }

    const confirmados = await this.prisma.matchAttendance.count({ where: { matchId, status: 'confirmed' } });
    const status = match.maxPlayers && confirmados >= match.maxPlayers ? 'waitlist' : 'confirmed';

    const attendance = existente
      ? await this.prisma.matchAttendance.update({ where: { id: existente.id }, data: { status } })
      : await this.prisma.matchAttendance.create({ data: { matchId, userId, status } });

    // Melhor-esforço, fora do caminho principal — avisa o criador, exceto
    // quando ele mesmo é quem confirmou.
    if (match.createdById !== userId) {
      const jogador = await this.prisma.user.findUnique({ where: { id: userId }, select: { fullName: true } });
      const mensagem =
        status === 'waitlist'
          ? `${jogador?.fullName ?? 'Um jogador'} entrou na lista de espera da sua partida.`
          : `${jogador?.fullName ?? 'Um jogador'} confirmou presença na sua partida.`;
      await this.notifications.notificar(
        match.createdById,
        'match_attendance',
        { matchId },
        'Partida',
        mensagem,
      );
    }

    return attendance;
  }

  async cancelarPresenca(matchId: string, userId: string) {
    const attendance = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId } },
    });
    if (!attendance) throw new NotFoundException('Você não tem presença confirmada nessa partida.');

    const eraConfirmado = attendance.status === 'confirmed';
    await this.prisma.matchAttendance.update({ where: { id: attendance.id }, data: { status: 'declined' } });

    // Promove o primeiro da lista de espera pro lugar que abriu, respeitando
    // ordem de chegada (quem entrou na fila primeiro sai primeiro).
    if (eraConfirmado) {
      const proximo = await this.prisma.matchAttendance.findFirst({
        where: { matchId, status: 'waitlist' },
        orderBy: { createdAt: 'asc' },
      });
      if (proximo) {
        await this.prisma.matchAttendance.update({ where: { id: proximo.id }, data: { status: 'confirmed' } });
        await this.notifications.notificar(
          proximo.userId,
          'match_waitlist_promoted',
          { matchId },
          'Você entrou na partida!',
          'Uma vaga abriu e você foi promovido da lista de espera pra confirmado.',
        );
      }
    }

    return { cancelado: true };
  }

  async registrarEvento(matchId: string, userId: string, dto: CreateEventDto) {
    const match = await this.exigirCriador(matchId, userId);
    if (STATUS_QUE_BLOQUEIA_NOVOS_EVENTOS.includes(match.status)) {
      throw new BadRequestException('Essa partida já foi encerrada — não é possível registrar novos eventos.');
    }

    const participante = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId: dto.userId } },
    });
    if (!participante) {
      throw new BadRequestException('Esse jogador não tem presença registrada nessa partida.');
    }

    // Mesma trava de unicidade do MVP usada em `elegerMvp` — impede que essa
    // rota genérica (mais antiga, só do criador) seja usada como atalho pra
    // burlar a regra de "um MVP só" por partida.
    if (dto.eventType === 'mvp') {
      const mvpExistente = await this.prisma.matchEvent.findFirst({ where: { matchId, eventType: 'mvp' } });
      if (mvpExistente) {
        throw new ConflictException('O MVP dessa partida já foi eleito.');
      }
    }

    // Congela o time do jogador aqui também, quando der (partida com os dois
    // times e jogador determinável) — mesma lógica de `registrarGol`, só que
    // best-effort: essa rota não exige que o time seja determinável (continua
    // aceitando cartão/MVP de partida avulsa, por exemplo).
    const teamId =
      match.homeTeamId && match.awayTeamId
        ? await this.timeDoJogador(match.homeTeamId, match.awayTeamId, dto.userId)
        : null;

    return this.prisma.matchEvent.create({
      data: { matchId, userId: dto.userId, teamId, eventType: dto.eventType, minute: dto.minute },
    });
  }

  // Inclui o placar (mesma lógica de obterPartida, Fase 9) em cada item da
  // listagem — é o que permite "Meus Jogos" servir de histórico real sem
  // precisar de uma tela nova (DALEH 1.0, fechamento do MVP).
  async minhasPartidas(userId: string) {
    const partidas = await this.prisma.match.findMany({
      where: {
        OR: [{ createdById: userId }, { attendance: { some: { userId, status: { in: ['confirmed', 'waitlist'] } } } }],
      },
      include: {
        modalidade: true,
        venue: true,
        homeTeam: { select: { id: true, name: true, crestUrl: true } },
        awayTeam: { select: { id: true, name: true, crestUrl: true } },
        events: { select: { teamId: true, eventType: true } },
        _count: { select: { attendance: true } },
      },
      orderBy: { scheduledAt: 'asc' },
    });

    return partidas.map(({ events, ...partida }) => {
      const temTimes = !!(partida.homeTeamId && partida.awayTeamId);
      const { homeScore, awayScore } = temTimes
        ? this.calcularPlacar(partida.homeTeamId!, partida.awayTeamId!, events)
        : { homeScore: null, awayScore: null };
      return { ...partida, homeScore, awayScore };
    });
  }

  private async exigirCriador(matchId: string, userId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) throw new NotFoundException('Partida não encontrada.');
    if (match.createdById !== userId) {
      throw new ForbiddenException('Só quem criou a partida pode fazer isso.');
    }
    return match;
  }
}

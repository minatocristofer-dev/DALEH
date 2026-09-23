import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTeamDto } from './dto/create-team.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';
import { CreateCallUpDto } from './dto/create-call-up.dto';
import { RespondCallUpDto } from './dto/respond-call-up.dto';

@Injectable()
export class TeamsService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    private teamAuth: TeamAuthorizationService,
  ) {}

  async criarTime(userId: string, dto: CreateTeamDto) {
    return this.prisma.$transaction(async (tx) => {
      const time = await tx.team.create({
        data: {
          name: dto.name,
          city: dto.city,
          state: dto.state,
          crestUrl: dto.crestUrl,
          ownerId: userId,
        },
      });

      await tx.teamMember.create({
        data: { teamId: time.id, userId, papel: 'CAPITAO', status: 'active' },
      });

      return time;
    });
  }

  async listarMeusTimes(userId: string) {
    const membros = await this.prisma.teamMember.findMany({
      where: { userId, status: 'active' },
      include: {
        team: {
          include: { _count: { select: { members: { where: { status: 'active' } } } } },
        },
      },
    });
    // totalMembros vem do _count do Prisma — necessário pra tela "Meus Times"
    // mostrar quantidade de jogadores sem o Flutter ter que buscar cada time.
    return membros.map((m) => {
      const { _count, ...time } = m.team;
      return { ...time, meuPapel: m.papel, totalMembros: _count.members };
    });
  }

  // Só o dono ou capitão/vice-capitão do time pode trocar o escudo — mesma
  // checagem usada pra convocar/gerenciar elenco. `crestUrl` já vem pronto
  // de quem fez o upload (SupabaseStorageService).
  async atualizarEscudo(teamId: string, userId: string, crestUrl: string) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);
    await this.prisma.team.update({ where: { id: teamId }, data: { crestUrl } });
    return this.obterTime(teamId);
  }

  async obterTime(teamId: string) {
    const time = await this.prisma.team.findUnique({
      where: { id: teamId },
      include: {
        members: {
          where: { status: 'active' },
          include: {
            user: {
              select: {
                id: true,
                fullName: true,
                avatarUrl: true,
                // Só a primeira modalidade cadastrada do jogador (mesma
                // convenção de "modalidadePrincipal" usada no Player Card —
                // não existe conceito de "modalidade principal" no schema,
                // então é sempre a primeira, nunca inventada).
                playerModalidades: { take: 1, include: { modalidade: true } },
              },
            },
          },
        },
      },
    });
    if (!time) throw new NotFoundException('Time não encontrado.');

    const membrosComPosicao = time.members.map((m) => {
      const { playerModalidades, ...user } = m.user;
      return { ...m, user, posicaoPrincipal: playerModalidades[0]?.posicaoPrincipal ?? null };
    });

    return { ...time, members: await this.comEstatisticasDoElenco(teamId, membrosComPosicao) };
  }

  // Estatísticas reais por jogador do elenco (jogos/gols/mvp), calculadas a
  // partir do MatchEvent.teamId congelado (Fase 9) — nunca derivadas do
  // TeamMember atual, então não regridem se alguém sair do time depois de
  // ter jogado. "Jogos" conta presença confirmada em partida onde ESTE time
  // (casa ou fora) participou; "mvp" idem, já que o evento de MVP não tem
  // teamId (não é gol/assistência, não precisa do congelamento).
  private async comEstatisticasDoElenco<T extends { userId: string }>(teamId: string, members: T[]) {
    const timeJogouNaPartida = { OR: [{ homeTeamId: teamId }, { awayTeamId: teamId }] };
    const [gols, mvps, jogos] = await Promise.all([
      this.prisma.matchEvent.groupBy({
        by: ['userId'],
        where: { teamId, eventType: 'goal' },
        _count: { _all: true },
      }),
      this.prisma.matchEvent.groupBy({
        by: ['userId'],
        where: { eventType: 'mvp', match: timeJogouNaPartida },
        _count: { _all: true },
      }),
      this.prisma.matchAttendance.groupBy({
        by: ['userId'],
        where: { status: 'confirmed', match: timeJogouNaPartida },
        _count: { _all: true },
      }),
    ]);

    const mapaDe = (linhas: { userId: string; _count: { _all: number } }[]) =>
      new Map(linhas.map((l) => [l.userId, l._count._all]));
    const golsPorJogador = mapaDe(gols);
    const mvpsPorJogador = mapaDe(mvps);
    const jogosPorJogador = mapaDe(jogos);

    return members.map((m) => ({
      ...m,
      estatisticas: {
        jogos: jogosPorJogador.get(m.userId) ?? 0,
        gols: golsPorJogador.get(m.userId) ?? 0,
        mvp: mvpsPorJogador.get(m.userId) ?? 0,
      },
    }));
  }

  async adicionarMembro(teamId: string, userId: string, dto: AddMemberDto) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);

    if (!dto.userId && !dto.email) {
      throw new BadRequestException('Informe userId ou email do jogador a adicionar.');
    }

    const jogador = dto.userId
      ? await this.prisma.user.findUnique({ where: { id: dto.userId } })
      : await this.prisma.user.findUnique({ where: { email: dto.email } });

    if (!jogador) {
      throw new NotFoundException('Jogador não encontrado — precisa já ter conta no DALEH.');
    }

    const existente = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId: jogador.id } },
    });

    let membro;
    if (existente) {
      if (existente.status === 'active') {
        throw new ConflictException('Esse jogador já está no elenco.');
      }
      membro = await this.prisma.teamMember.update({
        where: { id: existente.id },
        data: { status: 'active', papel: 'JOGADOR' },
      });
    } else {
      membro = await this.prisma.teamMember.create({
        data: { teamId, userId: jogador.id, papel: 'JOGADOR', status: 'active' },
      });
    }

    const time = await this.prisma.team.findUnique({ where: { id: teamId } });
    await this.notifications.notificar(
      jogador.id,
      'team_member_added',
      { teamId },
      'Novo time',
      `Você entrou no time ${time?.name ?? ''}.`,
    );

    return membro;
  }

  async atualizarMembro(teamId: string, alvoUserId: string, userId: string, dto: UpdateMemberDto) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId: alvoUserId } },
    });
    if (!membro || membro.status !== 'active') {
      throw new NotFoundException('Esse jogador não está no elenco.');
    }

    // Só checa duplicidade entre membros ATIVOS — um número que ficou com
    // alguém que já saiu do time não pode travar aquele número pra sempre
    // (por isso não existe constraint de unicidade no banco, ver schema).
    if (dto.numeroCamisa != null) {
      const jaUsado = await this.prisma.teamMember.findFirst({
        where: { teamId, status: 'active', numeroCamisa: dto.numeroCamisa, id: { not: membro.id } },
      });
      if (jaUsado) {
        throw new ConflictException(`O número ${dto.numeroCamisa} já está sendo usado por outro jogador deste time.`);
      }
    }

    return this.prisma.teamMember.update({
      where: { id: membro.id },
      data: {
        papel: dto.papel,
        ...(dto.numeroCamisa !== undefined ? { numeroCamisa: dto.numeroCamisa } : {}),
      },
    });
  }

  async removerMembro(teamId: string, alvoUserId: string, userId: string) {
    const souEuMesmo = alvoUserId === userId;
    if (!souEuMesmo) {
      await this.teamAuth.exigirCapitaoOuDono(teamId, userId);
    }

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId: alvoUserId } },
    });
    if (!membro || membro.status !== 'active') {
      throw new NotFoundException('Esse jogador não está no elenco.');
    }

    await this.prisma.teamMember.update({ where: { id: membro.id }, data: { status: 'removed' } });

    // Só notifica quando é remoção feita por outra pessoa — quem sai por
    // conta própria não precisa ser avisado de algo que ele mesmo fez.
    if (!souEuMesmo) {
      const time = await this.prisma.team.findUnique({ where: { id: teamId } });
      await this.notifications.notificar(
        alvoUserId,
        'team_member_removed',
        { teamId },
        'Saída do time',
        `Você foi removido do time ${time?.name ?? ''}.`,
      );
    }

    return { removido: true };
  }

  async convocar(teamId: string, userId: string, dto: CreateCallUpDto) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);

    // Fase 9 — impede convocar o mesmo time de novo pra mesma partida (ex:
    // duplo clique, ou reexecutar um seed). Convocação "solta" (sem
    // matchId) continua sem essa trava, porque não há partida pra comparar.
    if (dto.matchId) {
      const jaConvocado = await this.prisma.callUp.findFirst({ where: { teamId, matchId: dto.matchId } });
      if (jaConvocado) {
        throw new ConflictException('Esse time já foi convocado pra essa partida.');
      }
    }

    const elenco = await this.prisma.teamMember.findMany({
      where: { teamId, status: 'active' },
    });
    if (elenco.length === 0) {
      throw new BadRequestException('Esse time não tem nenhum jogador no elenco ainda.');
    }

    const convocacoes = await this.prisma.$transaction(
      elenco.map((membro) =>
        this.prisma.callUp.create({
          data: {
            teamId,
            matchId: dto.matchId,
            userId: membro.userId,
            venueNameSnapshot: dto.venueNameSnapshot,
            scheduledDate: new Date(dto.scheduledDate),
            scheduledTime: dto.scheduledTime,
          },
        }),
      ),
    );

    // Notificação + push são melhor-esforço, fora da transação — um push que
    // falha não pode desfazer a convocação que já foi criada.
    for (const callUp of convocacoes) {
      await this.notifications.notificar(
        callUp.userId,
        'call_up',
        {
          callUpId: callUp.id,
          teamId,
          venueNameSnapshot: dto.venueNameSnapshot,
          scheduledDate: dto.scheduledDate,
          scheduledTime: dto.scheduledTime,
        },
        'Convocação',
        `Você foi convocado pra ${dto.venueNameSnapshot} em ${dto.scheduledDate} às ${dto.scheduledTime}`,
      );
    }

    return convocacoes;
  }

  async listarConvocacoesDoTime(teamId: string, userId: string) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);
    return this.prisma.callUp.findMany({
      where: { teamId },
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async minhasConvocacoes(userId: string) {
    return this.prisma.callUp.findMany({
      where: { userId },
      include: { team: { select: { id: true, name: true, crestUrl: true } } },
      orderBy: [{ status: 'asc' }, { scheduledDate: 'asc' }],
    });
  }

  async responderConvocacao(callUpId: string, userId: string, dto: RespondCallUpDto) {
    const callUp = await this.prisma.callUp.findUnique({ where: { id: callUpId } });
    if (!callUp) throw new NotFoundException('Convocação não encontrada.');
    if (callUp.userId !== userId) {
      throw new ForbiddenException('Essa convocação não é sua.');
    }

    // Confirmar a convocação também confirma a presença (MatchAttendance) na
    // partida vinculada — é essa tabela que a súmula (Fase 8) usa como
    // escalação real. Só se aplica quando a convocação tem `matchId` (pode
    // ser nula) e quando o status vai pra CONFIRMADO. `upsert` na chave
    // composta `matchId_userId` (@@unique já existente em MatchAttendance)
    // garante idempotência sem precisar de migration nem de checagem manual
    // de duplicidade. Recusar (RECUSADO) não mexe em nenhuma presença já
    // existente — não havia essa cascata antes, e não inventamos uma agora.
    if (dto.status === 'CONFIRMADO' && callUp.matchId) {
      const matchId = callUp.matchId;
      return this.prisma.$transaction(async (tx) => {
        const convocacaoAtualizada = await tx.callUp.update({
          where: { id: callUpId },
          data: { status: dto.status, respondedAt: new Date() },
        });
        await tx.matchAttendance.upsert({
          where: { matchId_userId: { matchId, userId } },
          create: { matchId, userId, status: 'confirmed' },
          update: { status: 'confirmed' },
        });
        return convocacaoAtualizada;
      });
    }

    return this.prisma.callUp.update({
      where: { id: callUpId },
      data: { status: dto.status, respondedAt: new Date() },
    });
  }
}

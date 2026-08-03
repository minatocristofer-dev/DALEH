import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTeamDto } from './dto/create-team.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';
import { CreateCallUpDto } from './dto/create-call-up.dto';
import { RespondCallUpDto } from './dto/respond-call-up.dto';

const PAPEIS_DE_GESTAO = ['CAPITAO', 'VICE_CAPITAO'];

@Injectable()
export class TeamsService {
  constructor(private prisma: PrismaService) {}

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
      include: { team: true },
    });
    return membros.map((m) => ({ ...m.team, meuPapel: m.papel }));
  }

  async obterTime(teamId: string) {
    const time = await this.prisma.team.findUnique({
      where: { id: teamId },
      include: {
        members: {
          where: { status: 'active' },
          include: { user: { select: { id: true, fullName: true, avatarUrl: true } } },
        },
      },
    });
    if (!time) throw new NotFoundException('Time não encontrado.');
    return time;
  }

  async adicionarMembro(teamId: string, userId: string, dto: AddMemberDto) {
    await this.exigirCapitaoOuDono(teamId, userId);

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

    if (existente) {
      if (existente.status === 'active') {
        throw new ConflictException('Esse jogador já está no elenco.');
      }
      return this.prisma.teamMember.update({
        where: { id: existente.id },
        data: { status: 'active', papel: 'JOGADOR' },
      });
    }

    return this.prisma.teamMember.create({
      data: { teamId, userId: jogador.id, papel: 'JOGADOR', status: 'active' },
    });
  }

  async atualizarMembro(teamId: string, alvoUserId: string, userId: string, dto: UpdateMemberDto) {
    await this.exigirCapitaoOuDono(teamId, userId);

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId: alvoUserId } },
    });
    if (!membro || membro.status !== 'active') {
      throw new NotFoundException('Esse jogador não está no elenco.');
    }

    return this.prisma.teamMember.update({ where: { id: membro.id }, data: { papel: dto.papel } });
  }

  async removerMembro(teamId: string, alvoUserId: string, userId: string) {
    const souEuMesmo = alvoUserId === userId;
    if (!souEuMesmo) {
      await this.exigirCapitaoOuDono(teamId, userId);
    }

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId: alvoUserId } },
    });
    if (!membro || membro.status !== 'active') {
      throw new NotFoundException('Esse jogador não está no elenco.');
    }

    await this.prisma.teamMember.update({ where: { id: membro.id }, data: { status: 'removed' } });
    return { removido: true };
  }

  async convocar(teamId: string, userId: string, dto: CreateCallUpDto) {
    await this.exigirCapitaoOuDono(teamId, userId);

    const elenco = await this.prisma.teamMember.findMany({
      where: { teamId, status: 'active' },
    });
    if (elenco.length === 0) {
      throw new BadRequestException('Esse time não tem nenhum jogador no elenco ainda.');
    }

    return this.prisma.$transaction(async (tx) => {
      const convocacoes = [];
      for (const membro of elenco) {
        const callUp = await tx.callUp.create({
          data: {
            teamId,
            matchId: dto.matchId,
            userId: membro.userId,
            venueNameSnapshot: dto.venueNameSnapshot,
            scheduledDate: new Date(dto.scheduledDate),
            scheduledTime: dto.scheduledTime,
          },
        });
        await tx.notification.create({
          data: {
            userId: membro.userId,
            type: 'call_up',
            payload: {
              callUpId: callUp.id,
              teamId,
              venueNameSnapshot: dto.venueNameSnapshot,
              scheduledDate: dto.scheduledDate,
              scheduledTime: dto.scheduledTime,
            },
          },
        });
        convocacoes.push(callUp);
      }
      return convocacoes;
    });
  }

  async listarConvocacoesDoTime(teamId: string, userId: string) {
    await this.exigirCapitaoOuDono(teamId, userId);
    return this.prisma.callUp.findMany({
      where: { teamId },
      include: { user: { select: { id: true, fullName: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async minhasConvocacoes(userId: string) {
    return this.prisma.callUp.findMany({
      where: { userId },
      orderBy: [{ status: 'asc' }, { scheduledDate: 'asc' }],
    });
  }

  async responderConvocacao(callUpId: string, userId: string, dto: RespondCallUpDto) {
    const callUp = await this.prisma.callUp.findUnique({ where: { id: callUpId } });
    if (!callUp) throw new NotFoundException('Convocação não encontrada.');
    if (callUp.userId !== userId) {
      throw new ForbiddenException('Essa convocação não é sua.');
    }

    return this.prisma.callUp.update({
      where: { id: callUpId },
      data: { status: dto.status, respondedAt: new Date() },
    });
  }

  private async exigirCapitaoOuDono(teamId: string, userId: string) {
    const time = await this.prisma.team.findUnique({ where: { id: teamId } });
    if (!time) throw new NotFoundException('Time não encontrado.');
    if (time.ownerId === userId) return time;

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId } },
    });
    if (!membro || membro.status !== 'active' || !PAPEIS_DE_GESTAO.includes(membro.papel)) {
      throw new ForbiddenException('Você precisa ser capitão ou dono deste time pra fazer isso.');
    }
    return time;
  }
}

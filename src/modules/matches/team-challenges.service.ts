import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTeamChallengeDto } from './dto/create-team-challenge.dto';
import { CreateChallengeRequestDto } from './dto/create-challenge-request.dto';

const PAPEIS_DE_GESTAO = ['CAPITAO', 'VICE_CAPITAO'];

@Injectable()
export class TeamChallengesService {
  constructor(private prisma: PrismaService) {}

  async criarDesafio(userId: string, dto: CreateTeamChallengeDto) {
    await this.exigirCapitaoOuDono(dto.teamId, userId);

    const modalidade = await this.prisma.modalidade.findUnique({ where: { key: dto.modalidade } });
    if (!modalidade) throw new BadRequestException('Modalidade inválida.');

    return this.prisma.teamChallenge.create({
      data: {
        teamId: dto.teamId,
        modalidadeId: modalidade.id,
        city: dto.city,
        venueId: dto.venueId,
        scheduledDate: new Date(dto.scheduledDate),
        scheduledTime: dto.scheduledTime,
        desiredLevel: dto.desiredLevel,
      },
    });
  }

  listarDesafios(city?: string, modalidade?: string) {
    return this.prisma.teamChallenge.findMany({
      where: {
        status: 'ABERTA',
        ...(city ? { city: { contains: city, mode: 'insensitive' } } : {}),
        ...(modalidade ? { modalidade: { key: modalidade as any } } : {}),
      },
      include: { team: true, modalidade: true },
      orderBy: { scheduledDate: 'asc' },
    });
  }

  async solicitar(challengeId: string, userId: string, dto: CreateChallengeRequestDto) {
    const desafio = await this.prisma.teamChallenge.findUnique({ where: { id: challengeId } });
    if (!desafio) throw new NotFoundException('Desafio não encontrado.');
    if (desafio.status !== 'ABERTA') throw new BadRequestException('Esse desafio não está mais aberto.');
    if (desafio.teamId === dto.requestingTeamId) {
      throw new BadRequestException('Seu time não pode solicitar o próprio desafio.');
    }

    await this.exigirCapitaoOuDono(dto.requestingTeamId, userId);

    const existente = await this.prisma.challengeRequest.findUnique({
      where: { challengeId_requestingTeamId: { challengeId, requestingTeamId: dto.requestingTeamId } },
    });
    if (existente) throw new ConflictException('Seu time já solicitou esse desafio.');

    return this.prisma.challengeRequest.create({
      data: { challengeId, requestingTeamId: dto.requestingTeamId },
    });
  }

  async aceitar(challengeId: string, requestId: string, userId: string) {
    const desafio = await this.prisma.teamChallenge.findUnique({ where: { id: challengeId } });
    if (!desafio) throw new NotFoundException('Desafio não encontrado.');
    await this.exigirCapitaoOuDono(desafio.teamId, userId);

    const solicitacao = await this.prisma.challengeRequest.findUnique({ where: { id: requestId } });
    if (!solicitacao || solicitacao.challengeId !== challengeId) {
      throw new NotFoundException('Solicitação não encontrada.');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.challengeRequest.update({ where: { id: requestId }, data: { status: 'ACEITA' } });
      // Todas as outras solicitações do mesmo desafio são recusadas automaticamente —
      // evita dois times "confirmados" pro mesmo horário.
      await tx.challengeRequest.updateMany({
        where: { challengeId, id: { not: requestId } },
        data: { status: 'RECUSADA' },
      });
      return tx.teamChallenge.update({
        where: { id: challengeId },
        data: { status: 'CONFIRMADA', opponentTeamId: solicitacao.requestingTeamId },
      });
    });
  }

  async meusDesafios(userId: string) {
    const meusTimesIds = await this.idsDosMeusTimes(userId);

    const comoOrganizador = await this.prisma.teamChallenge.findMany({
      where: { teamId: { in: meusTimesIds } },
      include: { requests: { include: { requestingTeam: true } } },
      orderBy: { scheduledDate: 'asc' },
    });

    const minhasSolicitacoes = await this.prisma.challengeRequest.findMany({
      where: { requestingTeamId: { in: meusTimesIds } },
      include: { challenge: { include: { team: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return { comoOrganizador, minhasSolicitacoes };
  }

  private async idsDosMeusTimes(userId: string): Promise<string[]> {
    const [times, membros] = await Promise.all([
      this.prisma.team.findMany({ where: { ownerId: userId }, select: { id: true } }),
      this.prisma.teamMember.findMany({
        where: { userId, status: 'active', papel: { in: PAPEIS_DE_GESTAO as any } },
        select: { teamId: true },
      }),
    ]);
    return Array.from(new Set([...times.map((t) => t.id), ...membros.map((m) => m.teamId)]));
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

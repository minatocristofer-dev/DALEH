import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export const PAPEIS_DE_GESTAO_DE_TIME = ['CAPITAO', 'VICE_CAPITAO'];

/**
 * Centraliza a checagem de "é dono ou capitão/vice deste time?", usada por
 * TeamsService e TeamChallengesService. Extraído da duplicação idêntica que
 * existia nos dois lugares — comportamento preservado byte a byte.
 */
@Injectable()
export class TeamAuthorizationService {
  constructor(private prisma: PrismaService) {}

  async exigirCapitaoOuDono(teamId: string, userId: string) {
    const time = await this.prisma.team.findUnique({ where: { id: teamId } });
    if (!time) throw new NotFoundException('Time não encontrado.');
    if (time.ownerId === userId) return time;

    const membro = await this.prisma.teamMember.findUnique({
      where: { teamId_userId: { teamId, userId } },
    });
    if (!membro || membro.status !== 'active' || !PAPEIS_DE_GESTAO_DE_TIME.includes(membro.papel)) {
      throw new ForbiddenException('Você precisa ser capitão ou dono deste time pra fazer isso.');
    }
    return time;
  }

  /**
   * IDs de quem pode "falar pelo time" (dono + capitão/vice ativos) — usado
   * pra saber quem notificar em eventos do time (ex: desafio recebido/aceito).
   */
  async obterGestoresDoTime(teamId: string): Promise<string[]> {
    const time = await this.prisma.team.findUnique({ where: { id: teamId } });
    if (!time) throw new NotFoundException('Time não encontrado.');

    const membrosDeGestao = await this.prisma.teamMember.findMany({
      where: { teamId, status: 'active', papel: { in: PAPEIS_DE_GESTAO_DE_TIME as any } },
      select: { userId: true },
    });

    return Array.from(new Set([time.ownerId, ...membrosDeGestao.map((m) => m.userId)]));
  }
}

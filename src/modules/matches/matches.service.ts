import { BadRequestException, ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateMatchDto } from './dto/create-match.dto';
import { UpdateMatchStatusDto } from './dto/update-match-status.dto';
import { CreateEventDto } from './dto/create-event.dto';

@Injectable()
export class MatchesService {
  constructor(private prisma: PrismaService) {}

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
      include: { modalidade: true, venue: true, _count: { select: { attendance: true } } },
      orderBy: { scheduledAt: 'asc' },
    });
  }

  async obterPartida(id: string) {
    const partida = await this.prisma.match.findUnique({
      where: { id },
      include: {
        modalidade: true,
        venue: true,
        attendance: { include: { user: { select: { id: true, fullName: true, avatarUrl: true } } } },
        events: true,
      },
    });
    if (!partida) throw new NotFoundException('Partida não encontrada.');
    return partida;
  }

  async atualizarStatus(id: string, userId: string, dto: UpdateMatchStatusDto) {
    await this.exigirCriador(id, userId);
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

    if (existente) {
      return this.prisma.matchAttendance.update({ where: { id: existente.id }, data: { status } });
    }
    return this.prisma.matchAttendance.create({ data: { matchId, userId, status } });
  }

  async cancelarPresenca(matchId: string, userId: string) {
    const attendance = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId } },
    });
    if (!attendance) throw new NotFoundException('Você não tem presença confirmada nessa partida.');

    const eraConfirmado = attendance.status === 'confirmed';
    await this.prisma.matchAttendance.update({ where: { id: attendance.id }, data: { status: 'declined' } });

    // Promove alguém da lista de espera pro lugar que abriu. O schema não tem
    // um campo de ordem/timestamp em MatchAttendance, então não dá pra
    // garantir estritamente "quem entrou primeiro na espera" — pega o
    // primeiro que o banco retornar.
    if (eraConfirmado) {
      const proximo = await this.prisma.matchAttendance.findFirst({ where: { matchId, status: 'waitlist' } });
      if (proximo) {
        await this.prisma.matchAttendance.update({ where: { id: proximo.id }, data: { status: 'confirmed' } });
      }
    }

    return { cancelado: true };
  }

  async registrarEvento(matchId: string, userId: string, dto: CreateEventDto) {
    await this.exigirCriador(matchId, userId);

    const participante = await this.prisma.matchAttendance.findUnique({
      where: { matchId_userId: { matchId, userId: dto.userId } },
    });
    if (!participante) {
      throw new BadRequestException('Esse jogador não tem presença registrada nessa partida.');
    }

    return this.prisma.matchEvent.create({
      data: { matchId, userId: dto.userId, eventType: dto.eventType, minute: dto.minute },
    });
  }

  minhasPartidas(userId: string) {
    return this.prisma.match.findMany({
      where: {
        OR: [{ createdById: userId }, { attendance: { some: { userId, status: { in: ['confirmed', 'waitlist'] } } } }],
      },
      include: { modalidade: true, venue: true },
      orderBy: { scheduledAt: 'asc' },
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

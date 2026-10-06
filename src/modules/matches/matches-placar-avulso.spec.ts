import { BadRequestException } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('MatchesService — placar de partida avulsa (lado A / lado B)', () => {
  let prisma: any;
  let service: MatchesService;

  const avulsa = { id: 'm1', createdById: 'criador', homeTeamId: null, awayTeamId: null, status: 'in_progress', visibility: 'public' };
  const comTimes = { ...avulsa, homeTeamId: 'casa', awayTeamId: 'fora' };

  beforeEach(() => {
    prisma = {
      match: { findUnique: jest.fn().mockResolvedValue(avulsa) },
      matchAttendance: { findUnique: jest.fn().mockResolvedValue({ userId: 'jogador' }) },
      matchEvent: { create: jest.fn().mockResolvedValue({}), findFirst: jest.fn() },
    };
    service = new MatchesService(
      prisma as unknown as PrismaService,
      {} as NotificationsService,
      { exigirCapitaoOuDono: jest.fn() } as unknown as TeamAuthorizationService,
    );
  });

  describe('registrarEvento', () => {
    it('gol em partida avulsa sem lado é recusado', async () => {
      await expect(service.registrarEvento('m1', 'criador', { userId: 'jogador', eventType: 'goal' })).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.matchEvent.create).not.toHaveBeenCalled();
    });

    it('gol em partida avulsa grava o lado escolhido', async () => {
      await service.registrarEvento('m1', 'criador', { userId: 'jogador', eventType: 'goal', lado: 'B' });
      expect(prisma.matchEvent.create.mock.calls[0][0].data).toMatchObject({ eventType: 'goal', lado: 'B', teamId: null });
    });

    it('cartão em partida avulsa aceita lado opcional', async () => {
      await service.registrarEvento('m1', 'criador', { userId: 'jogador', eventType: 'yellow', lado: 'A' });
      expect(prisma.matchEvent.create.mock.calls[0][0].data).toMatchObject({ eventType: 'yellow', lado: 'A' });
    });

    it('partida com times não aceita lado (o time vem do jogador)', async () => {
      prisma.match.findUnique.mockResolvedValue(comTimes);
      await expect(service.registrarEvento('m1', 'criador', { userId: 'jogador', eventType: 'goal', lado: 'A' })).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('placar em obterPartida', () => {
    it('conta gols por lado e ignora cartões e assistências', async () => {
      prisma.match.findUnique.mockResolvedValue({
        ...avulsa,
        attendance: [],
        events: [
          { eventType: 'goal', lado: 'A' },
          { eventType: 'goal', lado: 'A' },
          { eventType: 'goal', lado: 'B' },
          { eventType: 'assist', lado: 'B' },
          { eventType: 'yellow', lado: 'A' },
        ],
      });

      const partida = await service.obterPartida('m1', 'criador');

      expect(partida.homeScore).toBe(2);
      expect(partida.awayScore).toBe(1);
    });

    it('sem gols, o placar é 0 × 0', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...avulsa, attendance: [], events: [] });
      const partida = await service.obterPartida('m1', 'criador');
      expect(partida.homeScore).toBe(0);
      expect(partida.awayScore).toBe(0);
    });
  });
});

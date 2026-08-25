import { BadRequestException, ConflictException } from '@nestjs/common';
import { TeamChallengesService } from './team-challenges.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('TeamChallengesService — marketplace de adversário', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamChallengesService;

  beforeEach(() => {
    prisma = {
      teamChallenge: { findUnique: jest.fn(), create: jest.fn(), findMany: jest.fn(), update: jest.fn() },
      challengeRequest: {
        findUnique: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      modalidade: { findUnique: jest.fn() },
      team: { findMany: jest.fn() },
      teamMember: { findMany: jest.fn() },
      $transaction: jest.fn(),
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn().mockResolvedValue({ id: 'time-solicitante' }),
      obterGestoresDoTime: jest.fn().mockResolvedValue([]),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamChallengesService(
      prisma as unknown as PrismaService,
      teamAuth as unknown as TeamAuthorizationService,
      notifications as unknown as NotificationsService,
    );
  });

  describe('solicitar', () => {
    it('rejeita quando o time já solicitou esse mesmo desafio (409)', async () => {
      prisma.teamChallenge.findUnique.mockResolvedValue({ id: 'desafio-1', status: 'ABERTA', teamId: 'time-dono' });
      prisma.challengeRequest.findUnique.mockResolvedValue({ id: 'solicitacao-existente' });

      await expect(
        service.solicitar('desafio-1', 'user-1', { requestingTeamId: 'time-solicitante' } as any),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejeita quando o próprio time tenta solicitar seu desafio', async () => {
      prisma.teamChallenge.findUnique.mockResolvedValue({
        id: 'desafio-1',
        status: 'ABERTA',
        teamId: 'time-solicitante',
      });

      await expect(
        service.solicitar('desafio-1', 'user-1', { requestingTeamId: 'time-solicitante' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('notifica os gestores do time organizador quando chega uma solicitação', async () => {
      prisma.teamChallenge.findUnique.mockResolvedValue({ id: 'desafio-1', status: 'ABERTA', teamId: 'time-dono' });
      prisma.challengeRequest.findUnique.mockResolvedValue(null);
      prisma.challengeRequest.create.mockResolvedValue({ id: 'nova-solicitacao' });
      teamAuth.obterGestoresDoTime.mockResolvedValue(['user-dono-organizador']);

      await service.solicitar('desafio-1', 'user-1', { requestingTeamId: 'time-solicitante' } as any);

      expect(teamAuth.obterGestoresDoTime).toHaveBeenCalledWith('time-dono');
      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-dono-organizador',
        'challenge_request_received',
        expect.objectContaining({ challengeId: 'desafio-1' }),
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('aceitar', () => {
    it('confirma o desafio, cria o Match vinculando os dois times e recusa as demais solicitações concorrentes', async () => {
      prisma.teamChallenge.findUnique.mockResolvedValue({
        id: 'desafio-1',
        teamId: 'time-dono',
        venueId: 'venue-1',
        modalidadeId: 'modalidade-1',
        scheduledDate: new Date('2026-09-10T00:00:00.000Z'),
        scheduledTime: '20:00',
      });
      prisma.challengeRequest.findUnique.mockResolvedValue({
        id: 'solicitacao-aceita',
        challengeId: 'desafio-1',
        requestingTeamId: 'time-vencedor',
      });
      prisma.challengeRequest.findMany.mockResolvedValue([
        { id: 'solicitacao-perdedora', challengeId: 'desafio-1', requestingTeamId: 'time-perdedor' },
      ]);

      const txChallengeRequestUpdate = jest.fn();
      const txChallengeRequestUpdateMany = jest.fn();
      const txMatchCreate = jest.fn().mockResolvedValue({ id: 'match-novo' });
      const txTeamChallengeUpdate = jest.fn().mockResolvedValue({ status: 'CONFIRMADA', matchId: 'match-novo' });
      prisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          challengeRequest: { update: txChallengeRequestUpdate, updateMany: txChallengeRequestUpdateMany },
          teamChallenge: { update: txTeamChallengeUpdate },
          match: { create: txMatchCreate },
        }),
      );
      teamAuth.obterGestoresDoTime.mockImplementation((teamId: string) =>
        Promise.resolve([`gestor-${teamId}`]),
      );

      const resultado = await service.aceitar('desafio-1', 'solicitacao-aceita', 'user-dono');

      expect(resultado).toEqual({ status: 'CONFIRMADA', matchId: 'match-novo' });
      expect(txChallengeRequestUpdateMany).toHaveBeenCalledWith({
        where: { challengeId: 'desafio-1', id: { not: 'solicitacao-aceita' } },
        data: { status: 'RECUSADA' },
      });
      expect(txMatchCreate).toHaveBeenCalledWith({
        data: expect.objectContaining({
          homeTeamId: 'time-dono',
          awayTeamId: 'time-vencedor',
          venueId: 'venue-1',
          modalidadeId: 'modalidade-1',
        }),
      });
      expect(txTeamChallengeUpdate).toHaveBeenCalledWith({
        where: { id: 'desafio-1' },
        data: { status: 'CONFIRMADA', opponentTeamId: 'time-vencedor', matchId: 'match-novo' },
      });
      // Times envolvidos no aceite são notificados de "challenge_accepted"...
      expect(notifications.notificar).toHaveBeenCalledWith(
        'gestor-time-dono',
        'challenge_accepted',
        expect.objectContaining({ matchId: 'match-novo' }),
        expect.any(String),
        expect.any(String),
      );
      // ...e o time cuja solicitação foi recusada em cascata é avisado separadamente.
      expect(notifications.notificar).toHaveBeenCalledWith(
        'gestor-time-perdedor',
        'challenge_request_declined',
        expect.objectContaining({ challengeId: 'desafio-1' }),
        expect.any(String),
        expect.any(String),
      );
    });
  });
});

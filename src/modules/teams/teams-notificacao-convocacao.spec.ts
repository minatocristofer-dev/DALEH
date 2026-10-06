import { TeamsService } from './teams.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('TeamsService — avisa gestores e criador quando a convocação é respondida', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamsService;

  const convocacao = {
    id: 'callup-1',
    teamId: 'time-1',
    matchId: 'match-1',
    userId: 'user-jogador',
    status: 'PENDENTE',
    venueNameSnapshot: 'Arena Teste',
    scheduledDate: new Date('2026-10-10T00:00:00.000Z'),
    scheduledTime: '19:00',
  };

  beforeEach(() => {
    prisma = {
      callUp: { findUnique: jest.fn().mockResolvedValue(convocacao), update: jest.fn().mockResolvedValue({ ...convocacao }) },
      matchAttendance: { upsert: jest.fn().mockResolvedValue({}) },
      user: { findUnique: jest.fn().mockResolvedValue({ fullName: 'Cristofer' }) },
      match: { findUnique: jest.fn().mockResolvedValue({ createdById: 'criador-amistoso' }) },
      $transaction: jest.fn((fn: any) => fn(prisma)),
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn(),
      // capitão, vice e o próprio jogador (que não deve se avisar) + criador repetido
      obterGestoresDoTime: jest.fn().mockResolvedValue(['capitao', 'vice', 'user-jogador']),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamsService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  it('confirmar avisa capitão, vice e criador da partida, sem avisar o próprio jogador nem repetir ninguém', async () => {
    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });

    const destinos = notifications.notificar.mock.calls.map((c) => c[0]).sort();
    expect(destinos).toEqual(['capitao', 'criador-amistoso', 'vice']);
    expect(notifications.notificar.mock.calls.every((c) => c[1] === 'call_up_response')).toBe(true);
  });

  it('recusar também avisa, com a mensagem de recusa', async () => {
    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'RECUSADO' });

    const corpo = notifications.notificar.mock.calls[0][4];
    expect(corpo).toContain('Cristofer recusou a convocação');
    expect(corpo).toContain('Arena Teste');
  });

  it('convocação sem partida vinculada avisa só os gestores do time', async () => {
    prisma.callUp.findUnique.mockResolvedValue({ ...convocacao, matchId: null });

    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'RECUSADO' });

    expect(notifications.notificar.mock.calls.map((c) => c[0]).sort()).toEqual(['capitao', 'vice']);
    expect(prisma.match.findUnique).not.toHaveBeenCalled();
  });
});

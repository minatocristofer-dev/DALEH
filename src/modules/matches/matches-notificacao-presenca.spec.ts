import { MatchesService } from './matches.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('MatchesService — avisa quem gerencia quando a presença muda', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: MatchesService;

  const amistoso = { id: 'm1', createdById: 'criador', homeTeamId: null, awayTeamId: null, maxPlayers: null };
  const partidaComTimes = { id: 'm1', createdById: 'criador', homeTeamId: 'casa', awayTeamId: 'fora', maxPlayers: null };

  beforeEach(() => {
    prisma = {
      match: { findUnique: jest.fn().mockResolvedValue(amistoso) },
      matchAttendance: {
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(null),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn().mockResolvedValue({ id: 'a1', status: 'confirmed' }),
        update: jest.fn().mockResolvedValue({ id: 'a1' }),
      },
      user: { findUnique: jest.fn().mockResolvedValue({ fullName: 'Lucas' }) },
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn(),
      obterGestoresDoTime: jest.fn(async (teamId: string) => (teamId === 'casa' ? ['cap-casa'] : ['cap-fora'])),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new MatchesService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  it('partida avulsa: confirmar avisa só o criador', async () => {
    await service.confirmarPresenca('m1', 'jogador');

    expect(notifications.notificar.mock.calls.map((c) => c[0])).toEqual(['criador']);
    expect(notifications.notificar.mock.calls[0][1]).toBe('match_attendance');
    expect(notifications.notificar.mock.calls[0][4]).toContain('confirmou presença');
  });

  it('partida com times: confirmar avisa criador e capitães dos dois times', async () => {
    prisma.match.findUnique.mockResolvedValue(partidaComTimes);

    await service.confirmarPresenca('m1', 'jogador');

    expect(notifications.notificar.mock.calls.map((c) => c[0]).sort()).toEqual(['cap-casa', 'cap-fora', 'criador']);
  });

  it('quem confirma não recebe o próprio aviso', async () => {
    prisma.match.findUnique.mockResolvedValue(partidaComTimes);
    teamAuth.obterGestoresDoTime.mockResolvedValue(['criador', 'jogador']);

    await service.confirmarPresenca('m1', 'jogador');

    expect(notifications.notificar.mock.calls.map((c) => c[0])).not.toContain('jogador');
  });

  it('cancelar presença também avisa quem gerencia', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue({ id: 'a1', status: 'confirmed' });
    prisma.match.findUnique.mockResolvedValue(partidaComTimes);

    await service.cancelarPresenca('m1', 'jogador');

    expect(notifications.notificar.mock.calls.map((c) => c[0]).sort()).toEqual(['cap-casa', 'cap-fora', 'criador']);
    expect(notifications.notificar.mock.calls[0][4]).toContain('cancelou presença');
  });
});

import { BadRequestException, ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { TeamsService } from './teams.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('TeamsService — responderConvocacao (Fase 8, complemento)', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamsService;

  beforeEach(() => {
    prisma = {
      callUp: { findUnique: jest.fn(), update: jest.fn() },
      matchAttendance: { upsert: jest.fn().mockResolvedValue({}) },
      $transaction: jest.fn((fn: any) => fn(prisma)),
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn(),
      obterGestoresDoTime: jest.fn().mockResolvedValue([]),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamsService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  const convocacaoComPartida = {
    id: 'callup-1',
    teamId: 'time-1',
    matchId: 'match-1',
    userId: 'user-jogador',
    status: 'PENDENTE',
  };

  it('1. jogador confirma convocação — CallUp passa pra CONFIRMADO', async () => {
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, status: 'CONFIRMADO' });

    const resultado = await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });

    expect(resultado.status).toBe('CONFIRMADO');
    expect(prisma.callUp.update).toHaveBeenCalledWith({
      where: { id: 'callup-1' },
      data: { status: 'CONFIRMADO', respondedAt: expect.any(Date) },
    });
  });

  it('2. jogador confirma convocação — cria/atualiza MatchAttendance como confirmed pra partida vinculada', async () => {
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, status: 'CONFIRMADO' });

    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });

    expect(prisma.matchAttendance.upsert).toHaveBeenCalledWith({
      where: { matchId_userId: { matchId: 'match-1', userId: 'user-jogador' } },
      create: { matchId: 'match-1', userId: 'user-jogador', status: 'confirmed' },
      update: { status: 'confirmed' },
    });
  });

  it('3. confirmar duas vezes seguidas não cria presença duplicada — sempre passa pela mesma chave upsert', async () => {
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, status: 'CONFIRMADO' });

    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });
    await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });

    expect(prisma.matchAttendance.upsert).toHaveBeenCalledTimes(2);
    const [primeira, segunda] = prisma.matchAttendance.upsert.mock.calls;
    expect(primeira[0].where).toEqual(segunda[0].where); // mesma chave matchId_userId nas duas vezes
  });

  it('4. presença já existente (ex: auto-confirmada antes) é reutilizada/atualizada, não recriada', async () => {
    // upsert cobre os dois casos (existe/não existe) numa chamada só — o
    // teste confirma que o service sempre delega pro upsert, nunca faz um
    // findUnique+create manual que poderia rejeitar por duplicidade.
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, status: 'CONFIRMADO' });
    prisma.matchAttendance.upsert.mockResolvedValue({ matchId: 'match-1', userId: 'user-jogador', status: 'confirmed' });

    await expect(
      service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' }),
    ).resolves.toBeDefined();
    expect(prisma.matchAttendance.upsert).toHaveBeenCalledTimes(1);
  });

  it('5. jogador recusa a convocação — não cria/atualiza nenhuma presença', async () => {
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, status: 'RECUSADO' });

    const resultado = await service.responderConvocacao('callup-1', 'user-jogador', { status: 'RECUSADO' });

    expect(resultado.status).toBe('RECUSADO');
    expect(prisma.matchAttendance.upsert).not.toHaveBeenCalled();
  });

  it('6. usuário tentando responder convocação de outro jogador recebe 403 — nada é alterado', async () => {
    prisma.callUp.findUnique.mockResolvedValue(convocacaoComPartida);

    await expect(
      service.responderConvocacao('callup-1', 'user-intruso', { status: 'CONFIRMADO' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.callUp.update).not.toHaveBeenCalled();
    expect(prisma.matchAttendance.upsert).not.toHaveBeenCalled();
  });

  it('convocação inexistente continua devolvendo 404', async () => {
    prisma.callUp.findUnique.mockResolvedValue(null);

    await expect(
      service.responderConvocacao('callup-inexistente', 'user-jogador', { status: 'CONFIRMADO' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('7. convocação confirmada sem partida vinculada (matchId nulo) não cria presença e não crasha', async () => {
    prisma.callUp.findUnique.mockResolvedValue({ ...convocacaoComPartida, matchId: null });
    prisma.callUp.update.mockResolvedValue({ ...convocacaoComPartida, matchId: null, status: 'CONFIRMADO' });

    const resultado = await service.responderConvocacao('callup-1', 'user-jogador', { status: 'CONFIRMADO' });

    expect(resultado.status).toBe('CONFIRMADO');
    expect(prisma.matchAttendance.upsert).not.toHaveBeenCalled();
  });
});

describe('TeamsService — convocar (Fase 9, proteção contra convocação duplicada)', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamsService;

  beforeEach(() => {
    prisma = {
      callUp: { findFirst: jest.fn().mockResolvedValue(null), create: jest.fn() },
      teamMember: { findMany: jest.fn() },
      $transaction: jest.fn((arg: any) => (Array.isArray(arg) ? Promise.all(arg) : arg(prisma))),
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn().mockResolvedValue({ id: 'time-1' }),
      obterGestoresDoTime: jest.fn().mockResolvedValue([]),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamsService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  const dtoConvocacao = {
    matchId: 'match-1',
    venueNameSnapshot: 'Arena Teste',
    scheduledDate: '2026-09-10',
    scheduledTime: '20:00',
  };

  it('convoca o time normalmente quando ainda não existe convocação pra essa partida', async () => {
    prisma.teamMember.findMany.mockResolvedValue([{ userId: 'user-1' }, { userId: 'user-2' }]);
    prisma.callUp.create.mockImplementation(({ data }: any) => Promise.resolve({ id: `callup-${data.userId}`, ...data }));

    const resultado = await service.convocar('time-1', 'user-capitao', dtoConvocacao as any);

    expect(resultado).toHaveLength(2);
    expect(prisma.callUp.findFirst).toHaveBeenCalledWith({ where: { teamId: 'time-1', matchId: 'match-1' } });
  });

  it('convocar o mesmo time de novo pra mesma partida é rejeitado (409) — não cria convocação duplicada', async () => {
    prisma.callUp.findFirst.mockResolvedValue({ id: 'callup-existente', teamId: 'time-1', matchId: 'match-1' });

    await expect(service.convocar('time-1', 'user-capitao', dtoConvocacao as any)).rejects.toBeInstanceOf(
      ConflictException,
    );
    expect(prisma.teamMember.findMany).not.toHaveBeenCalled();
    expect(prisma.callUp.create).not.toHaveBeenCalled();
  });

  it('convocação sem matchId (solta, não ligada a partida) continua funcionando sem a trava de duplicidade', async () => {
    prisma.teamMember.findMany.mockResolvedValue([{ userId: 'user-1' }]);
    prisma.callUp.create.mockImplementation(({ data }: any) => Promise.resolve({ id: 'callup-1', ...data }));

    const { matchId: _semMatchId, ...dtoSemPartida } = dtoConvocacao;

    const resultado = await service.convocar('time-1', 'user-capitao', dtoSemPartida as any);

    expect(resultado).toHaveLength(1);
    expect(prisma.callUp.findFirst).not.toHaveBeenCalled();
  });

  it('elenco vazio continua rejeitado com 400, mesmo sem convocação prévia', async () => {
    prisma.teamMember.findMany.mockResolvedValue([]);

    await expect(service.convocar('time-1', 'user-capitao', dtoConvocacao as any)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});

describe('TeamsService — atualizarEscudo (upload de escudo do time)', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamsService;

  const timeSemElenco = { id: 'time-1', name: 'Time 1', crestUrl: 'https://exemplo/novo-escudo.png', members: [] };

  beforeEach(() => {
    prisma = {
      team: { findUnique: jest.fn().mockResolvedValue(timeSemElenco), update: jest.fn().mockResolvedValue(timeSemElenco) },
      matchEvent: { groupBy: jest.fn().mockResolvedValue([]) },
      matchAttendance: { groupBy: jest.fn().mockResolvedValue([]) },
    };
    teamAuth = { exigirCapitaoOuDono: jest.fn().mockResolvedValue(timeSemElenco), obterGestoresDoTime: jest.fn().mockResolvedValue([]) };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamsService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  it('dono/capitão consegue trocar o escudo — atualiza crestUrl e devolve o time atualizado', async () => {
    const resultado = await service.atualizarEscudo('time-1', 'user-capitao', 'https://exemplo/novo-escudo.png');

    expect(prisma.team.update).toHaveBeenCalledWith({
      where: { id: 'time-1' },
      data: { crestUrl: 'https://exemplo/novo-escudo.png' },
    });
    expect(resultado).toMatchObject({ id: 'time-1', crestUrl: 'https://exemplo/novo-escudo.png' });
  });

  it('quem não é dono/capitão/vice-capitão recebe 403 — nada é alterado', async () => {
    teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException('Você precisa ser capitão ou dono deste time pra fazer isso.'));

    await expect(
      service.atualizarEscudo('time-1', 'user-intruso', 'https://exemplo/novo-escudo.png'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.team.update).not.toHaveBeenCalled();
  });
});

describe('TeamsService — obterTime (Fase visual, estatísticas reais por jogador do elenco)', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: TeamsService;

  const timeComElenco = {
    id: 'time-1',
    name: 'Time 1',
    members: [
      {
        id: 'membro-1',
        teamId: 'time-1',
        userId: 'user-joao',
        papel: 'CAPITAO',
        status: 'active',
        user: {
          id: 'user-joao',
          fullName: 'João',
          avatarUrl: null,
          playerModalidades: [{ posicaoPrincipal: 'Atacante', modalidade: { key: 'FUTSAL' } }],
        },
      },
      {
        id: 'membro-2',
        teamId: 'time-1',
        userId: 'user-marcos',
        papel: 'JOGADOR',
        status: 'active',
        user: { id: 'user-marcos', fullName: 'Marcos', avatarUrl: null, playerModalidades: [] },
      },
    ],
  };

  beforeEach(() => {
    prisma = {
      team: { findUnique: jest.fn().mockResolvedValue(timeComElenco) },
      matchEvent: { groupBy: jest.fn().mockResolvedValue([]) },
      matchAttendance: { groupBy: jest.fn().mockResolvedValue([]) },
    };
    teamAuth = { exigirCapitaoOuDono: jest.fn(), obterGestoresDoTime: jest.fn().mockResolvedValue([]) };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new TeamsService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  it('devolve a posição principal de quem tem modalidade cadastrada, e null pra quem não tem (nunca inventada)', async () => {
    const time = await service.obterTime('time-1');

    expect(time.members[0]).toMatchObject({ userId: 'user-joao', posicaoPrincipal: 'Atacante' });
    expect(time.members[1]).toMatchObject({ userId: 'user-marcos', posicaoPrincipal: null });
  });

  it('devolve jogos/gols/mvp reais por jogador, calculados a partir do MatchEvent.teamId congelado (Fase 9)', async () => {
    prisma.matchEvent.groupBy.mockImplementation(({ where }: any) => {
      if (where.eventType === 'goal') {
        return Promise.resolve([{ userId: 'user-joao', _count: { _all: 3 } }]);
      }
      if (where.eventType === 'mvp') {
        return Promise.resolve([{ userId: 'user-joao', _count: { _all: 1 } }]);
      }
      return Promise.resolve([]);
    });
    prisma.matchAttendance.groupBy.mockResolvedValue([
      { userId: 'user-joao', _count: { _all: 5 } },
      { userId: 'user-marcos', _count: { _all: 2 } },
    ]);

    const time = await service.obterTime('time-1');

    expect(time.members[0]).toMatchObject({ userId: 'user-joao', estatisticas: { jogos: 5, gols: 3, mvp: 1 } });
    expect(time.members[1]).toMatchObject({ userId: 'user-marcos', estatisticas: { jogos: 2, gols: 0, mvp: 0 } });
  });

  it('jogador sem nenhum jogo/gol/mvp reais aparece zerado — nunca undefined ou inventado', async () => {
    const time = await service.obterTime('time-1');

    expect(time.members[0].estatisticas).toEqual({ jogos: 0, gols: 0, mvp: 0 });
    expect(time.members[1].estatisticas).toEqual({ jogos: 0, gols: 0, mvp: 0 });
  });

  it('gols contados usam o teamId congelado do evento, não o TeamMember atual', async () => {
    await service.obterTime('time-1');

    expect(prisma.matchEvent.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ teamId: 'time-1', eventType: 'goal' }) }),
    );
  });
});

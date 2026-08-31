import { BadRequestException, ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { MatchesService } from './matches.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('MatchesService', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock; obterGestoresDoTime: jest.Mock };
  let notifications: { notificar: jest.Mock };
  let service: MatchesService;

  beforeEach(() => {
    prisma = {
      match: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn(), findMany: jest.fn() },
      matchAttendance: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        count: jest.fn(),
      },
      matchEvent: { findFirst: jest.fn(), create: jest.fn() },
      callUp: { findFirst: jest.fn() },
      teamMember: { findFirst: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      playerModalidade: { findMany: jest.fn().mockResolvedValue([]) },
      modalidade: { findUnique: jest.fn() },
      user: { findUnique: jest.fn() },
      $transaction: jest.fn((fn: any) => fn(prisma)),
    };
    teamAuth = {
      exigirCapitaoOuDono: jest.fn().mockRejectedValue(new ForbiddenException()),
      obterGestoresDoTime: jest.fn().mockResolvedValue([]),
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new MatchesService(
      prisma as unknown as PrismaService,
      notifications as unknown as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  describe('obterPartida — proteção de partida privada', () => {
    const partidaPrivada = {
      id: 'match-1',
      createdById: 'user-criador',
      homeTeamId: null,
      awayTeamId: null,
      visibility: 'private',
    };

    it('permite acesso do criador da partida', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaPrivada);

      // Partida sem os dois times (homeTeamId/awayTeamId null) — obterPartida
      // acrescenta homeScore/awayScore nulos e souGestorDaSumula calculado
      // (aqui, true: o criador administra a súmula de partida avulsa).
      await expect(service.obterPartida('match-1', 'user-criador')).resolves.toEqual({
        ...partidaPrivada,
        homeScore: null,
        awayScore: null,
        souGestorDaSumula: true,
      });
    });

    it('permite acesso de quem já tem presença (attendance) registrada', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaPrivada);
      prisma.matchAttendance.findUnique.mockResolvedValue({ matchId: 'match-1', userId: 'user-participante' });

      await expect(service.obterPartida('match-1', 'user-participante')).resolves.toEqual({
        ...partidaPrivada,
        homeScore: null,
        awayScore: null,
        souGestorDaSumula: false,
      });
    });

    it('rejeita com 403 um usuário autenticado aleatório que só conhece o ID', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaPrivada);
      prisma.matchAttendance.findUnique.mockResolvedValue(null);
      prisma.callUp.findFirst.mockResolvedValue(null);

      await expect(service.obterPartida('match-1', 'user-aleatorio')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('continua permitindo acesso livre a partida pública', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...partidaPrivada, visibility: 'public' });

      await expect(service.obterPartida('match-1', 'qualquer-usuario')).resolves.toBeDefined();
      expect(prisma.matchAttendance.findUnique).not.toHaveBeenCalled();
    });
  });

  describe('confirmarPresenca — bloqueio de dupla confirmação', () => {
    it('rejeita com 409 quando o usuário já confirmou presença', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', maxPlayers: 10 });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });

      await expect(service.confirmarPresenca('match-1', 'user-1')).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('notifica o criador quando outro jogador confirma presença', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', maxPlayers: 10, createdById: 'user-criador' });
      prisma.matchAttendance.findUnique.mockResolvedValue(null);
      prisma.matchAttendance.count.mockResolvedValue(0);
      prisma.matchAttendance.create.mockResolvedValue({ id: 'attendance-1', status: 'confirmed' });
      prisma.user.findUnique.mockResolvedValue({ fullName: 'Jogador Teste' });

      await service.confirmarPresenca('match-1', 'user-jogador');

      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-criador',
        'match_attendance',
        { matchId: 'match-1' },
        expect.any(String),
        expect.stringContaining('confirmou presença'),
      );
    });

    it('não notifica quando o próprio criador confirma presença', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', maxPlayers: 10, createdById: 'user-criador' });
      prisma.matchAttendance.findUnique.mockResolvedValue(null);
      prisma.matchAttendance.count.mockResolvedValue(0);
      prisma.matchAttendance.create.mockResolvedValue({ id: 'attendance-1', status: 'confirmed' });

      await service.confirmarPresenca('match-1', 'user-criador');

      expect(notifications.notificar).not.toHaveBeenCalled();
    });
  });

  describe('cancelarPresenca — ordem de chegada da fila de espera', () => {
    it('promove o usuário que entrou primeiro na fila (menor createdAt), não o mais recente', async () => {
      prisma.matchAttendance.findUnique.mockResolvedValue({
        id: 'attendance-confirmado',
        status: 'confirmed',
      });
      prisma.matchAttendance.update.mockResolvedValue({});

      // Simula o comportamento real do banco: orderBy createdAt asc devolve
      // sempre o registro mais antigo, independentemente da ordem de inserção.
      prisma.matchAttendance.findFirst.mockImplementation(({ orderBy }: any) => {
        expect(orderBy).toEqual({ createdAt: 'asc' });
        return Promise.resolve({ id: 'usuario-A-entrou-primeiro', userId: 'user-A' });
      });

      await service.cancelarPresenca('match-1', 'user-que-cancelou');

      expect(prisma.matchAttendance.findFirst).toHaveBeenCalledWith({
        where: { matchId: 'match-1', status: 'waitlist' },
        orderBy: { createdAt: 'asc' },
      });
      expect(prisma.matchAttendance.update).toHaveBeenCalledWith({
        where: { id: 'usuario-A-entrou-primeiro' },
        data: { status: 'confirmed' },
      });
      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-A',
        'match_waitlist_promoted',
        { matchId: 'match-1' },
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('súmula digital (Fase 8) — registrarGol', () => {
    // Time A (home): João, Pedro. Time B (away): Marcos, Rafael. Todos com
    // presença confirmada nessa partida.
    const partidaComTimes = {
      id: 'match-1',
      homeTeamId: 'time-a',
      awayTeamId: 'time-b',
      status: 'scheduled',
      createdById: 'user-criador',
    };

    function membrosDosTimes() {
      return [
        { userId: 'user-joao', teamId: 'time-a' },
        { userId: 'user-pedro', teamId: 'time-a' },
        { userId: 'user-marcos', teamId: 'time-b' },
        { userId: 'user-rafael', teamId: 'time-b' },
      ];
    }

    function presencaConfirmada() {
      return { status: 'confirmed' };
    }

    beforeEach(() => {
      prisma.match.findUnique.mockResolvedValue(partidaComTimes);
      prisma.matchAttendance.findUnique.mockResolvedValue(presencaConfirmada());
      prisma.matchEvent.create.mockImplementation(({ data }: any) => Promise.resolve({ id: 'evento-novo', ...data }));
    });

    it('1. capitão do Time A consegue registrar gol', async () => {
      teamAuth.exigirCapitaoOuDono.mockImplementation((teamId: string) =>
        teamId === 'time-a' ? Promise.resolve({ id: teamId }) : Promise.reject(new ForbiddenException()),
      );
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-a' });

      const resultado = await service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao' });

      expect(resultado.gol).toMatchObject({ userId: 'user-joao', eventType: 'goal', teamId: 'time-a' });
      expect(resultado.assistencia).toBeNull();
    });

    it('teamId do gol é sempre determinado pelo backend (via timeDoJogador), nunca aceito do cliente — RegisterGoalDto nem tem esse campo', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      // O jogador só pode ser derivado como pertencente ao time-b aqui —
      // mesmo que um cliente malicioso tentasse forçar outro valor, o DTO
      // não tem campo teamId nenhum pra enviar, e o service ignora qualquer
      // coisa que não seja o resultado de timeDoJogador.
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-b' });

      const resultado = await service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-marcos' } as any);

      expect(resultado.gol.teamId).toBe('time-b');
    });

    it('2. capitão do Time B consegue registrar gol', async () => {
      teamAuth.exigirCapitaoOuDono.mockImplementation((teamId: string) =>
        teamId === 'time-b' ? Promise.resolve({ id: teamId }) : Promise.reject(new ForbiddenException()),
      );
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-b' });

      const resultado = await service.registrarGol('match-1', 'user-capitao-b', { scorerId: 'user-marcos' });

      expect(resultado.gol).toMatchObject({ userId: 'user-marcos', eventType: 'goal' });
    });

    it('3. jogador comum (não capitão/dono de nenhum dos times) recebe 403', async () => {
      teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException());

      await expect(
        service.registrarGol('match-1', 'user-jogador-comum', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.matchEvent.create).not.toHaveBeenCalled();
    });

    it('4. usuário fora da partida (não capitão de nenhum dos dois times) recebe 403', async () => {
      teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException());

      await expect(
        service.registrarGol('match-1', 'user-estranho', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('5. goleador precisa estar na escalação (com presença confirmada)', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-a' });
      prisma.matchAttendance.findUnique.mockResolvedValue(null); // não confirmou presença

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.matchEvent.create).not.toHaveBeenCalled();
    });

    it('goleador que não pertence a nenhum dos dois times é rejeitado', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockResolvedValue(null); // não é membro ativo de time-a nem time-b

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-de-fora' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('6. assistência precisa estar na escalação (com presença confirmada)', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-a' });
      prisma.matchAttendance.findUnique.mockImplementation(({ where }: any) =>
        Promise.resolve(where.matchId_userId.userId === 'user-joao' ? presencaConfirmada() : null),
      );

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao', assistId: 'user-pedro' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('7. assistência de jogador do time adversário é rejeitada', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockImplementation(({ where }: any) => {
        const alvo = where.userId;
        const membros = membrosDosTimes();
        const membro = membros.find((m) => m.userId === alvo);
        return Promise.resolve(membro ? { teamId: membro.teamId } : null);
      });
      prisma.matchAttendance.findUnique.mockResolvedValue(presencaConfirmada());

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao', assistId: 'user-marcos' }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.matchEvent.create).not.toHaveBeenCalled();
    });

    it('7b. assistência de jogador do MESMO time do goleador é aceita', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockImplementation(({ where }: any) => {
        const membro = membrosDosTimes().find((m) => m.userId === where.userId);
        return Promise.resolve(membro ? { teamId: membro.teamId } : null);
      });
      prisma.matchAttendance.findUnique.mockResolvedValue(presencaConfirmada());

      const resultado = await service.registrarGol('match-1', 'user-capitao-a', {
        scorerId: 'user-joao',
        assistId: 'user-pedro',
      });

      expect(resultado.gol).toMatchObject({ userId: 'user-joao', eventType: 'goal' });
      expect(resultado.assistencia).toMatchObject({ userId: 'user-pedro', eventType: 'assist' });
    });

    it('8. assistência pode ser nula (gol sem assistId)', async () => {
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.teamMember.findFirst.mockResolvedValue({ teamId: 'time-a' });

      const resultado = await service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao' });

      expect(resultado.assistencia).toBeNull();
    });

    it('10. partida encerrada (finished) não aceita novo gol', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...partidaComTimes, status: 'finished' });

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(teamAuth.exigirCapitaoOuDono).not.toHaveBeenCalled();
    });

    it('partida cancelada não aceita novo gol', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...partidaComTimes, status: 'cancelled' });

      await expect(
        service.registrarGol('match-1', 'user-capitao-a', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('partida avulsa (sem os dois times) rejeita registro de gol com placar por time', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...partidaComTimes, homeTeamId: null, awayTeamId: null });

      await expect(
        service.registrarGol('match-1', 'user-criador', { scorerId: 'user-joao' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('súmula digital (Fase 8) — placar calculado (obterPartida)', () => {
    it('9. placar é derivado da contagem de MatchEvent tipo goal, usando o teamId congelado em cada evento (Fase 9)', async () => {
      prisma.match.findUnique.mockResolvedValue({
        id: 'match-1',
        homeTeamId: 'time-a',
        awayTeamId: 'time-b',
        visibility: 'public',
        createdById: 'user-criador',
        events: [
          { userId: 'user-joao', teamId: 'time-a', eventType: 'goal' },
          { userId: 'user-joao', teamId: 'time-a', eventType: 'goal' },
          { userId: 'user-marcos', teamId: 'time-b', eventType: 'goal' },
          { userId: 'user-pedro', teamId: 'time-a', eventType: 'assist' },
        ],
      });

      const partida = await service.obterPartida('match-1');

      expect(partida.homeScore).toBe(2);
      expect(partida.awayScore).toBe(1);
    });

    it('placar histórico não muda se o jogador sair do time depois do gol (Fase 9 — cenário da auditoria)', async () => {
      // O evento já foi criado com teamId='time-a' congelado no momento do
      // gol. Mesmo que o jogador não seja mais membro ativo de nenhum time
      // hoje (o mock global de teamMember.findMany devolve [] — usado só
      // pela escalação, não pelo placar), o placar precisa continuar
      // contando o gol pro Time A.
      prisma.match.findUnique.mockResolvedValue({
        id: 'match-1',
        homeTeamId: 'time-a',
        awayTeamId: 'time-b',
        visibility: 'public',
        createdById: 'user-criador',
        events: [{ userId: 'user-joao', teamId: 'time-a', eventType: 'goal' }],
      });

      const partida = await service.obterPartida('match-1');

      expect(partida.homeScore).toBe(1);
      expect(partida.awayScore).toBe(0);
    });

    it('evento antigo sem teamId (pré-Fase 9, não migrável com segurança) não é contado em nenhum dos dois lados', async () => {
      prisma.match.findUnique.mockResolvedValue({
        id: 'match-1',
        homeTeamId: 'time-a',
        awayTeamId: 'time-b',
        visibility: 'public',
        createdById: 'user-criador',
        events: [
          { userId: 'user-joao', teamId: null, eventType: 'goal' },
          { userId: 'user-pedro', teamId: 'time-b', eventType: 'goal' },
        ],
      });

      const partida = await service.obterPartida('match-1');

      expect(partida.homeScore).toBe(0);
      expect(partida.awayScore).toBe(1);
    });
  });

  describe('escalação (Fase visual) — teamId e posição por participante em obterPartida', () => {
    const partidaComTimes = {
      id: 'match-1',
      homeTeamId: 'time-a',
      awayTeamId: 'time-b',
      modalidadeId: 'modalidade-society',
      visibility: 'public',
      createdById: 'user-criador',
      events: [],
      attendance: [
        { userId: 'user-joao', status: 'confirmed' },
        { userId: 'user-marcos', status: 'confirmed' },
        { userId: 'user-sem-time', status: 'confirmed' },
      ],
    };

    it('resolve o time (casa/fora) e a posição de cada participante a partir do TeamMember e do PlayerModalidade atuais', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaComTimes);
      prisma.teamMember.findMany.mockResolvedValue([
        { userId: 'user-joao', teamId: 'time-a' },
        { userId: 'user-marcos', teamId: 'time-b' },
      ]);
      prisma.playerModalidade.findMany.mockResolvedValue([
        { userId: 'user-joao', posicaoPrincipal: 'Atacante' },
      ]);

      const partida = await service.obterPartida('match-1');

      expect(partida.attendance).toEqual([
        { userId: 'user-joao', status: 'confirmed', teamId: 'time-a', posicaoPrincipal: 'Atacante' },
        { userId: 'user-marcos', status: 'confirmed', teamId: 'time-b', posicaoPrincipal: null },
        { userId: 'user-sem-time', status: 'confirmed', teamId: null, posicaoPrincipal: null },
      ]);
      expect(prisma.playerModalidade.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: expect.objectContaining({ modalidadeId: 'modalidade-society' }) }),
      );
    });

    it('participante sem time ativo nem posição cadastrada não tem nenhum valor inventado (fica null)', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaComTimes);
      // teamMember.findMany e playerModalidade.findMany usando o default [] do beforeEach.

      const partida = await service.obterPartida('match-1');

      for (const participante of partida.attendance as any[]) {
        expect(participante.teamId).toBeNull();
        expect(participante.posicaoPrincipal).toBeNull();
      }
    });

    it('partida avulsa (sem os dois times) não enriquece attendance com teamId/posição', async () => {
      prisma.match.findUnique.mockResolvedValue({
        ...partidaComTimes,
        homeTeamId: null,
        awayTeamId: null,
      });

      const partida = await service.obterPartida('match-1');

      expect(partida.attendance).toEqual(partidaComTimes.attendance);
      expect(prisma.playerModalidade.findMany).not.toHaveBeenCalled();
    });
  });

  describe('minhasPartidas — placar na listagem (fechamento MVP, "Meus Jogos" como histórico)', () => {
    it('cada partida com os dois times vem com homeScore/awayScore calculados a partir do teamId congelado', async () => {
      prisma.match.findMany.mockResolvedValue([
        {
          id: 'match-1',
          homeTeamId: 'time-a',
          awayTeamId: 'time-b',
          events: [
            { teamId: 'time-a', eventType: 'goal' },
            { teamId: 'time-b', eventType: 'goal' },
            { teamId: 'time-b', eventType: 'goal' },
          ],
        },
      ]);

      const partidas = await service.minhasPartidas('user-1');

      expect(partidas[0].homeScore).toBe(1);
      expect(partidas[0].awayScore).toBe(2);
      expect((partidas[0] as any).events).toBeUndefined();
    });

    it('partida avulsa (sem os dois times) vem com placar null, sem quebrar', async () => {
      prisma.match.findMany.mockResolvedValue([
        { id: 'match-2', homeTeamId: null, awayTeamId: null, events: [] },
      ]);

      const partidas = await service.minhasPartidas('user-1');

      expect(partidas[0].homeScore).toBeNull();
      expect(partidas[0].awayScore).toBeNull();
    });
  });

  describe('súmula digital (Fase 8) — elegerMvp', () => {
    const partidaFinalizadaComTimes = {
      id: 'match-1',
      homeTeamId: 'time-a',
      awayTeamId: 'time-b',
      status: 'finished',
      createdById: 'user-criador',
    };

    it('MVP só pode ser eleito depois da partida finalizada', async () => {
      prisma.match.findUnique.mockResolvedValue({ ...partidaFinalizadaComTimes, status: 'scheduled' });

      await expect(
        service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-joao' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('11. MVP só pode ser jogador que participou da partida (presença confirmada)', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaFinalizadaComTimes);
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.matchAttendance.findUnique.mockResolvedValue(null);

      await expect(
        service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-de-fora' }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('12. MVP é único — segunda eleição na mesma partida é rejeitada com 409', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaFinalizadaComTimes);
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      prisma.matchEvent.findFirst.mockResolvedValue({ id: 'mvp-existente', eventType: 'mvp' });

      await expect(
        service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-joao' }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.matchEvent.create).not.toHaveBeenCalled();
    });

    it('capitão de um dos times consegue eleger o MVP', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaFinalizadaComTimes);
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      prisma.matchEvent.findFirst.mockResolvedValue(null);
      prisma.matchEvent.create.mockResolvedValue({ id: 'mvp-match-1', matchId: 'match-1', userId: 'user-joao', eventType: 'mvp' });

      const resultado = await service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-joao' });

      expect(resultado).toMatchObject({ userId: 'user-joao', eventType: 'mvp' });
      // id determinístico (mvp-<matchId>) — é essa a trava de corrida da Fase 9.
      expect(prisma.matchEvent.create).toHaveBeenCalledWith({
        data: { id: 'mvp-match-1', matchId: 'match-1', userId: 'user-joao', eventType: 'mvp' },
      });
    });

    it('Fase 9 — duas eleições de MVP "simultâneas" (corrida): a segunda é bloqueada mesmo passando pela checagem inicial', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaFinalizadaComTimes);
      teamAuth.exigirCapitaoOuDono.mockResolvedValue({ id: 'time-a' });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      // As duas passam pelo findFirst achando que ainda não há MVP (é
      // exatamente essa a janela de corrida que preocupava a auditoria).
      prisma.matchEvent.findFirst.mockResolvedValue(null);

      const erroDeChaveDuplicada = Object.assign(new Error('Unique constraint failed'), { code: 'P2002' });
      Object.setPrototypeOf(erroDeChaveDuplicada, Prisma.PrismaClientKnownRequestError.prototype);

      prisma.matchEvent.create
        .mockResolvedValueOnce({ id: 'mvp-match-1', matchId: 'match-1', userId: 'user-joao', eventType: 'mvp' })
        .mockRejectedValueOnce(erroDeChaveDuplicada);

      const primeira = await service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-joao' });
      expect(primeira).toMatchObject({ eventType: 'mvp' });

      await expect(
        service.elegerMvp('match-1', 'user-capitao-a', { userId: 'user-pedro' }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('jogador comum (não capitão/dono) não consegue eleger o MVP', async () => {
      prisma.match.findUnique.mockResolvedValue(partidaFinalizadaComTimes);
      teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException());

      await expect(
        service.elegerMvp('match-1', 'user-jogador-comum', { userId: 'user-joao' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('em partida avulsa (sem times), só o criador pode eleger o MVP', async () => {
      prisma.match.findUnique.mockResolvedValue({
        id: 'match-1',
        homeTeamId: null,
        awayTeamId: null,
        status: 'finished',
        createdById: 'user-criador',
      });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      prisma.matchEvent.findFirst.mockResolvedValue(null);
      prisma.matchEvent.create.mockResolvedValue({ id: 'mvp-1', eventType: 'mvp', userId: 'user-joao' });

      await expect(
        service.elegerMvp('match-1', 'user-jogador-qualquer', { userId: 'user-joao' }),
      ).rejects.toBeInstanceOf(ForbiddenException);

      await expect(
        service.elegerMvp('match-1', 'user-criador', { userId: 'user-joao' }),
      ).resolves.toMatchObject({ eventType: 'mvp' });
    });
  });

  describe('súmula digital (Fase 8) — finalização e integridade', () => {
    it('13. usuário que não é o criador não consegue finalizar a partida (atualizarStatus)', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'scheduled' });

      await expect(
        service.atualizarStatus('match-1', 'user-intruso', { status: 'finished' } as any),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.match.update).not.toHaveBeenCalled();
    });

    it('o criador consegue finalizar a partida', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'in_progress' });
      prisma.match.update.mockResolvedValue({ id: 'match-1', status: 'finished' });

      const resultado = await service.atualizarStatus('match-1', 'user-criador', { status: 'finished' } as any);

      expect(resultado.status).toBe('finished');
    });

    it('registrarEvento (rota antiga) também bloqueia novos eventos após a partida encerrada', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'finished' });

      await expect(
        service.registrarEvento('match-1', 'user-criador', { userId: 'user-joao', eventType: 'goal' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('registrarEvento (rota antiga) também impede um segundo MVP', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'in_progress' });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      prisma.matchEvent.findFirst.mockResolvedValue({ id: 'mvp-existente', eventType: 'mvp' });

      await expect(
        service.registrarEvento('match-1', 'user-criador', { userId: 'user-joao', eventType: 'mvp' } as any),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('14. dados/fluxos existentes continuam funcionando: registrarEvento com participante confirmado ainda cria o evento', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'scheduled' });
      prisma.matchAttendance.findUnique.mockResolvedValue({ status: 'confirmed' });
      prisma.matchEvent.create.mockResolvedValue({ id: 'evento-1', matchId: 'match-1', userId: 'user-joao', eventType: 'yellow' });

      const evento = await service.registrarEvento('match-1', 'user-criador', {
        userId: 'user-joao',
        eventType: 'yellow',
      } as any);

      expect(evento).toMatchObject({ eventType: 'yellow' });
    });
  });

  describe('Fase 9 — status da partida é uma máquina de estados com dois estados terminais', () => {
    it('scheduled → in_progress funciona', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'scheduled' });
      prisma.match.update.mockResolvedValue({ id: 'match-1', status: 'in_progress' });

      const resultado = await service.atualizarStatus('match-1', 'user-criador', { status: 'in_progress' } as any);

      expect(resultado.status).toBe('in_progress');
    });

    it('in_progress → finished funciona', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'in_progress' });
      prisma.match.update.mockResolvedValue({ id: 'match-1', status: 'finished' });

      const resultado = await service.atualizarStatus('match-1', 'user-criador', { status: 'finished' } as any);

      expect(resultado.status).toBe('finished');
    });

    it('scheduled → cancelled continua funcionando (fluxo de cancelamento existente, preservado)', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'scheduled' });
      prisma.match.update.mockResolvedValue({ id: 'match-1', status: 'cancelled' });

      const resultado = await service.atualizarStatus('match-1', 'user-criador', { status: 'cancelled' } as any);

      expect(resultado.status).toBe('cancelled');
    });

    it('finished → scheduled falha (não pode reabrir)', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'finished' });

      await expect(
        service.atualizarStatus('match-1', 'user-criador', { status: 'scheduled' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.match.update).not.toHaveBeenCalled();
    });

    it('finished → in_progress falha', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'finished' });

      await expect(
        service.atualizarStatus('match-1', 'user-criador', { status: 'in_progress' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('finished → cancelled falha', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'finished' });

      await expect(
        service.atualizarStatus('match-1', 'user-criador', { status: 'cancelled' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('partida cancelada não pode ser reaberta pra nenhum outro status', async () => {
      prisma.match.findUnique.mockResolvedValue({ id: 'match-1', createdById: 'user-criador', status: 'cancelled' });

      await expect(
        service.atualizarStatus('match-1', 'user-criador', { status: 'scheduled' } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.match.update).not.toHaveBeenCalled();
    });
  });
});

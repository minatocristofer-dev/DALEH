import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('MatchesService.marcarPagamento', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock };
  let service: MatchesService;

  const partidaAvulsa = { id: 'm1', createdById: 'criador', homeTeamId: null, awayTeamId: null };
  const partidaComTimes = { id: 'm1', createdById: 'criador', homeTeamId: 'casa', awayTeamId: 'fora' };

  beforeEach(() => {
    prisma = {
      match: { findUnique: jest.fn().mockResolvedValue(partidaAvulsa) },
      matchAttendance: { findUnique: jest.fn(), update: jest.fn().mockResolvedValue({}) },
    };
    teamAuth = { exigirCapitaoOuDono: jest.fn().mockRejectedValue(new ForbiddenException()) };
    service = new MatchesService(
      prisma as unknown as PrismaService,
      {} as NotificationsService,
      teamAuth as unknown as TeamAuthorizationService,
    );
  });

  const confirmado = { id: 'a1', userId: 'jogador', status: 'confirmed', pagoEm: null };

  it('criador de partida avulsa consegue marcar como pago, registrando quem marcou', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue(confirmado);

    await service.marcarPagamento('m1', 'criador', 'jogador', { pago: true });

    const data = prisma.matchAttendance.update.mock.calls[0][0].data;
    expect(data.pagoEm).toBeInstanceOf(Date);
    expect(data.marcadoPorId).toBe('criador');
  });

  it('volta para pendente limpando data e responsável', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue({ ...confirmado, pagoEm: new Date() });

    await service.marcarPagamento('m1', 'criador', 'jogador', { pago: false });

    expect(prisma.matchAttendance.update.mock.calls[0][0].data).toEqual({ pagoEm: null, marcadoPorId: null });
  });

  it('jogador comum não consegue alterar, mesmo estando na partida', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue(confirmado);

    await expect(service.marcarPagamento('m1', 'jogador', 'jogador', { pago: true })).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.matchAttendance.update).not.toHaveBeenCalled();
  });

  it('capitão de um dos times vinculados consegue marcar em partida com times', async () => {
    prisma.match.findUnique.mockResolvedValue(partidaComTimes);
    prisma.matchAttendance.findUnique.mockResolvedValue(confirmado);
    teamAuth.exigirCapitaoOuDono.mockImplementation(async (teamId: string) => {
      if (teamId === 'fora') return {};
      throw new ForbiddenException();
    });

    await service.marcarPagamento('m1', 'capitao-fora', 'jogador', { pago: true });

    expect(prisma.matchAttendance.update).toHaveBeenCalled();
  });

  it('capitão de time NÃO vinculado à partida é bloqueado', async () => {
    prisma.match.findUnique.mockResolvedValue(partidaComTimes);
    teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException());

    await expect(service.marcarPagamento('m1', 'estranho', 'jogador', { pago: true })).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('jogador que não está na partida retorna 404', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue(null);
    await expect(service.marcarPagamento('m1', 'criador', 'ninguem', { pago: true })).rejects.toBeInstanceOf(NotFoundException);
  });

  it('presença em lista de espera não entra no controle', async () => {
    prisma.matchAttendance.findUnique.mockResolvedValue({ ...confirmado, status: 'waitlist' });
    await expect(service.marcarPagamento('m1', 'criador', 'jogador', { pago: true })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('partida inexistente retorna 404', async () => {
    prisma.match.findUnique.mockResolvedValue(null);
    await expect(service.marcarPagamento('x', 'criador', 'jogador', { pago: true })).rejects.toBeInstanceOf(NotFoundException);
  });

  describe('definirValorQuadra', () => {
    beforeEach(() => {
      prisma.match.update = jest.fn().mockResolvedValue({ id: 'm1', valorQuadra: 200 });
    });

    it('criador informa o valor total da quadra', async () => {
      await service.definirValorQuadra('m1', 'criador', 200);
      expect(prisma.match.update.mock.calls[0][0].data).toEqual({ valorQuadra: 200 });
    });

    it('valor null limpa o valor informado', async () => {
      await service.definirValorQuadra('m1', 'criador', null);
      expect(prisma.match.update.mock.calls[0][0].data).toEqual({ valorQuadra: null });
    });

    it('jogador comum não consegue informar o valor', async () => {
      await expect(service.definirValorQuadra('m1', 'jogador', 200)).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.match.update).not.toHaveBeenCalled();
    });
  });
});

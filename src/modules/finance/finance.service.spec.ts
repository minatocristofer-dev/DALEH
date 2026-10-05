import { ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';
import { FinanceService } from './finance.service';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from '../../common/authorization/team-authorization.service';

describe('FinanceService', () => {
  let prisma: any;
  let teamAuth: { exigirCapitaoOuDono: jest.Mock };
  let service: FinanceService;

  beforeEach(() => {
    prisma = {
      team: { findUnique: jest.fn(), update: jest.fn() },
      teamMember: { findMany: jest.fn(), findUnique: jest.fn() },
      teamCharge: { create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn() },
      teamChargeItem: { findUnique: jest.fn(), update: jest.fn(), findMany: jest.fn() },
    };
    teamAuth = { exigirCapitaoOuDono: jest.fn().mockResolvedValue({}) };
    service = new FinanceService(prisma as unknown as PrismaService, teamAuth as unknown as TeamAuthorizationService);
  });

  describe('criarCobranca', () => {
    it('bloqueia quem não é capitão/dono e não cria nada', async () => {
      teamAuth.exigirCapitaoOuDono.mockRejectedValue(new ForbiddenException());
      await expect(service.criarCobranca('t1', 'u-comum', { titulo: 'Pelada', valor: 20 })).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.teamCharge.create).not.toHaveBeenCalled();
    });

    it('gera um item por membro ATIVO (ignora removidos e convidados)', async () => {
      prisma.teamMember.findMany.mockResolvedValue([{ userId: 'a' }, { userId: 'b' }]);
      prisma.teamCharge.create.mockResolvedValue({ id: 'c1' });

      await service.criarCobranca('t1', 'capitao', { titulo: '  Pelada de sábado ', valor: 20 });

      expect(prisma.teamMember.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { teamId: 't1', status: 'active' } }));
      const data = prisma.teamCharge.create.mock.calls[0][0].data;
      expect(data.titulo).toBe('Pelada de sábado');
      expect(data.itens.create).toEqual([{ userId: 'a' }, { userId: 'b' }]);
    });

    it('recusa cobrança em time sem jogadores ativos', async () => {
      prisma.teamMember.findMany.mockResolvedValue([]);
      await expect(service.criarCobranca('t1', 'capitao', { titulo: 'x', valor: 1 })).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('marcarPagamento', () => {
    it('marca como pago com data e quem marcou', async () => {
      prisma.teamCharge.findUnique.mockResolvedValue({ id: 'c1', teamId: 't1' });
      prisma.teamChargeItem.findUnique.mockResolvedValue({ id: 'i1' });
      prisma.teamChargeItem.update.mockResolvedValue({ userId: 'a', pagoEm: new Date() });

      await service.marcarPagamento('c1', 'capitao', 'a', { pago: true });

      const data = prisma.teamChargeItem.update.mock.calls[0][0].data;
      expect(data.pagoEm).toBeInstanceOf(Date);
      expect(data.marcadoPorId).toBe('capitao');
    });

    it('desmarca limpando data e responsável', async () => {
      prisma.teamCharge.findUnique.mockResolvedValue({ id: 'c1', teamId: 't1' });
      prisma.teamChargeItem.findUnique.mockResolvedValue({ id: 'i1' });
      prisma.teamChargeItem.update.mockResolvedValue({});

      await service.marcarPagamento('c1', 'capitao', 'a', { pago: false });

      expect(prisma.teamChargeItem.update.mock.calls[0][0].data).toEqual({ pagoEm: null, marcadoPorId: null });
    });

    it('404 quando o jogador não está na cobrança', async () => {
      prisma.teamCharge.findUnique.mockResolvedValue({ id: 'c1', teamId: 't1' });
      prisma.teamChargeItem.findUnique.mockResolvedValue(null);
      await expect(service.marcarPagamento('c1', 'capitao', 'estranho', { pago: true })).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('listarCobrancasDoTime', () => {
    it('jogador comum recebe só o próprio item e não é gestor', async () => {
      prisma.team.findUnique.mockResolvedValue({ id: 't1', ownerId: 'dono', pixKey: 'chave@pix', pixNome: 'Time' });
      prisma.teamMember.findUnique.mockResolvedValue({ status: 'active', papel: 'JOGADOR' });
      prisma.teamCharge.findMany.mockResolvedValue([]);

      const r = await service.listarCobrancasDoTime('t1', 'jogador');

      expect(r.souGestor).toBe(false);
      expect(r.pixKey).toBe('chave@pix');
      const where = prisma.teamCharge.findMany.mock.calls[0][0].where;
      expect(where.itens).toEqual({ some: { userId: 'jogador' } });
    });

    it('não-membro é bloqueado', async () => {
      prisma.team.findUnique.mockResolvedValue({ id: 't1', ownerId: 'dono', pixKey: null, pixNome: null });
      prisma.teamMember.findUnique.mockResolvedValue(null);
      await expect(service.listarCobrancasDoTime('t1', 'estranho')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });
});

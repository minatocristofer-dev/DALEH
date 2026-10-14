import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { VenuesService } from './venues.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('VenuesService — bloqueio de data (só o dono gerencia)', () => {
  let prisma: any;
  let service: VenuesService;

  const quadraDoDono = { id: 'venue-1', ownerId: 'user-dono' };

  beforeEach(() => {
    prisma = {
      venue: { findUnique: jest.fn().mockResolvedValue(quadraDoDono) },
      venueBlockedDate: {
        create: jest.fn(),
        findUnique: jest.fn(),
        delete: jest.fn(),
        findMany: jest.fn(),
      },
    };
    service = new VenuesService(prisma as unknown as PrismaService, {} as NotificationsService);
  });

  describe('bloquearData', () => {
    it('dono bloqueia uma data com motivo', async () => {
      prisma.venueBlockedDate.create.mockResolvedValue({ id: 'bloqueio-1', date: new Date('2026-12-25') });

      await service.bloquearData('venue-1', 'user-dono', { date: '2026-12-25', reason: 'Feriado' });

      expect(prisma.venueBlockedDate.create).toHaveBeenCalledWith({
        data: { venueId: 'venue-1', date: new Date('2026-12-25T00:00:00.000Z'), reason: 'Feriado' },
      });
    });

    it('jogador comum (não dono) não consegue bloquear', async () => {
      await expect(
        service.bloquearData('venue-1', 'user-jogador', { date: '2026-12-25' }),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.venueBlockedDate.create).not.toHaveBeenCalled();
    });

    it('bloquear a mesma data duas vezes dá conflito, não erro genérico', async () => {
      const erroPrisma = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
        code: 'P2002',
        clientVersion: '5.22.0',
      });
      prisma.venueBlockedDate.create.mockRejectedValue(erroPrisma);

      await expect(service.bloquearData('venue-1', 'user-dono', { date: '2026-12-25' })).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('desbloquearData', () => {
    it('dono remove um bloqueio existente', async () => {
      prisma.venueBlockedDate.findUnique.mockResolvedValue({ id: 'bloqueio-1', venueId: 'venue-1' });
      prisma.venueBlockedDate.delete.mockResolvedValue({});

      const resultado = await service.desbloquearData('venue-1', 'bloqueio-1', 'user-dono');

      expect(resultado).toEqual({ removido: true });
      expect(prisma.venueBlockedDate.delete).toHaveBeenCalledWith({ where: { id: 'bloqueio-1' } });
    });

    it('jogador comum não consegue desbloquear', async () => {
      await expect(service.desbloquearData('venue-1', 'bloqueio-1', 'user-jogador')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.venueBlockedDate.delete).not.toHaveBeenCalled();
    });

    it('bloqueio de outra quadra (ou inexistente) dá 404', async () => {
      prisma.venueBlockedDate.findUnique.mockResolvedValue({ id: 'bloqueio-1', venueId: 'outra-quadra' });
      await expect(service.desbloquearData('venue-1', 'bloqueio-1', 'user-dono')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('listarBloqueios', () => {
    it('jogador comum não consegue listar os bloqueios de gestão', async () => {
      await expect(service.listarBloqueios('venue-1', 'user-jogador')).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('disponibilidade considera o bloqueio', () => {
    it('data bloqueada: nenhum horário disponível, sem consultar slots', async () => {
      prisma.venue = { findUnique: jest.fn().mockResolvedValue({ id: 'venue-1', slots: [] }) };
      prisma.venueBlockedDate.findUnique.mockResolvedValue({ id: 'bloqueio-1' });
      prisma.venueSlot = { findMany: jest.fn() };

      const resultado = await service.disponibilidade('venue-1', '2026-12-25');

      expect(resultado).toEqual([]);
      expect(prisma.venueSlot.findMany).not.toHaveBeenCalled();
    });
  });
});

import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { VenuesService } from './venues.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

describe('VenuesService', () => {
  let prisma: any;
  let notifications: { notificar: jest.Mock };
  let service: VenuesService;

  beforeEach(() => {
    prisma = {
      venue: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn(), findMany: jest.fn() },
      venueSlot: { findUnique: jest.fn(), create: jest.fn(), delete: jest.fn(), findMany: jest.fn() },
      booking: { findFirst: jest.fn(), create: jest.fn(), findMany: jest.fn(), update: jest.fn(), findUnique: jest.fn() },
      user: { findMany: jest.fn(), findUnique: jest.fn() },
    };
    notifications = { notificar: jest.fn().mockResolvedValue({}) };
    service = new VenuesService(prisma as unknown as PrismaService, notifications as unknown as NotificationsService);
  });

  describe('reservar', () => {
    const slot = { id: 'slot-1', venueId: 'venue-1', venue: { id: 'venue-1', ownerId: 'user-dono', name: 'Arena Teste' } };

    it('cria a reserva quando o horário está livre naquela data', async () => {
      prisma.venueSlot.findUnique.mockResolvedValue(slot);
      prisma.booking.findFirst.mockResolvedValue(null);
      prisma.booking.create.mockResolvedValue({ id: 'booking-1', status: 'pending' });

      const resultado = await service.reservar('venue-1', 'slot-1', 'user-1', {
        date: '2026-09-01',
      } as any);

      expect(resultado).toEqual({ id: 'booking-1', status: 'pending' });
      expect(prisma.booking.create).toHaveBeenCalled();
    });

    it('rejeita com 409 ao tentar reservar um horário já ocupado na mesma data', async () => {
      prisma.venueSlot.findUnique.mockResolvedValue(slot);
      prisma.booking.findFirst.mockResolvedValue({ id: 'booking-existente', status: 'confirmed' });

      await expect(
        service.reservar('venue-1', 'slot-1', 'user-2', { date: '2026-09-01' } as any),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.booking.create).not.toHaveBeenCalled();
    });

    it('notifica o dono da quadra quando uma nova reserva é criada', async () => {
      prisma.venueSlot.findUnique.mockResolvedValue(slot);
      prisma.booking.findFirst.mockResolvedValue(null);
      prisma.booking.create.mockResolvedValue({ id: 'booking-1', status: 'pending' });

      await service.reservar('venue-1', 'slot-1', 'user-1', { date: '2026-09-01' } as any);

      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-dono',
        'booking_created',
        expect.objectContaining({ bookingId: 'booking-1', venueId: 'venue-1' }),
        expect.any(String),
        expect.stringContaining('Arena Teste'),
      );
    });
  });

  describe('editarQuadra — autorização de dono', () => {
    it('permite quando o usuário é o dono da quadra', async () => {
      prisma.venue.findUnique.mockResolvedValue({ id: 'venue-1', ownerId: 'user-dono' });
      prisma.venue.update.mockResolvedValue({ id: 'venue-1' });

      await expect(service.editarQuadra('venue-1', 'user-dono', {} as any)).resolves.toBeDefined();
    });

    it('rejeita com 403 quando o usuário não é o dono da quadra', async () => {
      prisma.venue.findUnique.mockResolvedValue({ id: 'venue-1', ownerId: 'user-dono' });

      await expect(service.editarQuadra('venue-1', 'user-intruso', {} as any)).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.venue.update).not.toHaveBeenCalled();
    });
  });

  describe('reservasDaQuadra — reservas recebidas pelo dono', () => {
    it('devolve as reservas da quadra, com o nome de quem reservou resolvido', async () => {
      prisma.venue.findUnique.mockResolvedValue({ id: 'venue-1', ownerId: 'user-dono' });
      prisma.booking.findMany.mockResolvedValue([
        {
          id: 'booking-1',
          venueSlotId: 'slot-1',
          bookedById: 'user-locatario',
          date: new Date('2026-09-01T00:00:00.000Z'),
          status: 'pending',
          venueSlot: { id: 'slot-1', startTime: '18:00', endTime: '19:00', venue: { id: 'venue-1', name: 'Arena Teste' } },
        },
      ]);
      prisma.user.findMany.mockResolvedValue([
        { id: 'user-locatario', fullName: 'Jogador Teste', avatarUrl: null },
      ]);

      const resultado = await service.reservasDaQuadra('venue-1', 'user-dono');

      expect(prisma.booking.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { venueSlot: { venueId: 'venue-1' } } }),
      );
      expect(resultado[0].bookedByUser).toEqual({ id: 'user-locatario', fullName: 'Jogador Teste', avatarUrl: null });
    });

    it('rejeita com 403 quando o usuário não é dono da quadra', async () => {
      prisma.venue.findUnique.mockResolvedValue({ id: 'venue-1', ownerId: 'user-dono' });

      await expect(service.reservasDaQuadra('venue-1', 'user-intruso')).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.booking.findMany).not.toHaveBeenCalled();
    });

    it('lança 404 quando a quadra não existe', async () => {
      prisma.venue.findUnique.mockResolvedValue(null);

      await expect(service.reservasDaQuadra('venue-inexistente', 'user-dono')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('atualizarStatusReserva — notificações', () => {
    const bookingBase = {
      id: 'booking-1',
      bookedById: 'user-locatario',
      venueSlot: { venue: { id: 'venue-1', ownerId: 'user-dono', name: 'Arena Teste' } },
    };

    it('notifica o locatário quando o dono confirma a reserva', async () => {
      prisma.booking.findUnique.mockResolvedValue(bookingBase);
      prisma.booking.update.mockResolvedValue({ ...bookingBase, status: 'confirmed' });

      await service.atualizarStatusReserva('booking-1', 'user-dono', { status: 'confirmed' } as any);

      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-locatario',
        'booking_confirmed',
        expect.objectContaining({ bookingId: 'booking-1' }),
        expect.any(String),
        expect.stringContaining('confirmada'),
      );
    });

    it('notifica o locatário quando o dono cancela a reserva', async () => {
      prisma.booking.findUnique.mockResolvedValue(bookingBase);
      prisma.booking.update.mockResolvedValue({ ...bookingBase, status: 'cancelled' });

      await service.atualizarStatusReserva('booking-1', 'user-dono', { status: 'cancelled' } as any);

      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-locatario',
        'booking_cancelled_by_owner',
        expect.objectContaining({ bookingId: 'booking-1' }),
        expect.any(String),
        expect.stringContaining('cancelada'),
      );
    });

    it('rejeita com 403 quando quem tenta alterar não é o dono da quadra', async () => {
      prisma.booking.findUnique.mockResolvedValue(bookingBase);

      await expect(
        service.atualizarStatusReserva('booking-1', 'user-intruso', { status: 'confirmed' } as any),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(notifications.notificar).not.toHaveBeenCalled();
    });
  });

  describe('cancelarMinhaReserva — notificação pro dono', () => {
    it('notifica o dono da quadra quando o locatário cancela a própria reserva', async () => {
      prisma.booking.findUnique.mockResolvedValue({
        id: 'booking-1',
        bookedById: 'user-locatario',
        venueSlot: { venue: { id: 'venue-1', ownerId: 'user-dono', name: 'Arena Teste' } },
      });
      prisma.booking.update.mockResolvedValue({ id: 'booking-1', status: 'cancelled' });
      prisma.user.findUnique.mockResolvedValue({ fullName: 'Jogador Teste' });

      await service.cancelarMinhaReserva('booking-1', 'user-locatario');

      expect(notifications.notificar).toHaveBeenCalledWith(
        'user-dono',
        'booking_cancelled_by_renter',
        expect.objectContaining({ bookingId: 'booking-1', venueId: 'venue-1' }),
        expect.any(String),
        expect.stringContaining('Jogador Teste'),
      );
    });

    it('rejeita com 403 quando a reserva não é do usuário', async () => {
      prisma.booking.findUnique.mockResolvedValue({
        id: 'booking-1',
        bookedById: 'outro-usuario',
        venueSlot: { venue: { id: 'venue-1', ownerId: 'user-dono', name: 'Arena Teste' } },
      });

      await expect(service.cancelarMinhaReserva('booking-1', 'user-intruso')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(notifications.notificar).not.toHaveBeenCalled();
    });
  });
});

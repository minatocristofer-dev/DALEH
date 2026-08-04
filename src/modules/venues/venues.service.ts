import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { CreateSlotDto } from './dto/create-slot.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';

function inicioDoDia(dateStr: string) {
  const d = new Date(dateStr);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function fimDoDia(inicio: Date) {
  const fim = new Date(inicio);
  fim.setUTCDate(fim.getUTCDate() + 1);
  return fim;
}

@Injectable()
export class VenuesService {
  constructor(private prisma: PrismaService) {}

  criarQuadra(userId: string, dto: CreateVenueDto) {
    return this.prisma.venue.create({ data: { ...dto, ownerId: userId } });
  }

  // Não existe coluna "city" dedicada no schema — busca por texto livre no endereço.
  listarQuadras(cidade?: string) {
    return this.prisma.venue.findMany({
      where: cidade ? { address: { contains: cidade, mode: 'insensitive' } } : undefined,
      orderBy: { avgRating: 'desc' },
    });
  }

  minhasQuadras(userId: string) {
    return this.prisma.venue.findMany({ where: { ownerId: userId } });
  }

  async obterQuadra(id: string) {
    const quadra = await this.prisma.venue.findUnique({ where: { id }, include: { slots: true } });
    if (!quadra) throw new NotFoundException('Quadra não encontrada.');
    return quadra;
  }

  async editarQuadra(id: string, userId: string, dto: UpdateVenueDto) {
    await this.exigirDono(id, userId);
    return this.prisma.venue.update({ where: { id }, data: dto });
  }

  async criarSlot(venueId: string, userId: string, dto: CreateSlotDto) {
    await this.exigirDono(venueId, userId);
    return this.prisma.venueSlot.create({ data: { venueId, ...dto } });
  }

  async removerSlot(venueId: string, slotId: string, userId: string) {
    await this.exigirDono(venueId, userId);
    const slot = await this.prisma.venueSlot.findUnique({ where: { id: slotId } });
    if (!slot || slot.venueId !== venueId) throw new NotFoundException('Horário não encontrado.');
    await this.prisma.venueSlot.delete({ where: { id: slotId } });
    return { removido: true };
  }

  async disponibilidade(venueId: string, dateStr: string) {
    await this.obterQuadra(venueId);

    const inicio = inicioDoDia(dateStr);
    const fim = fimDoDia(inicio);
    // 0=Segunda...6=Domingo (padrão do schema); Date.getUTCDay() é 0=Domingo...6=Sábado.
    const diaSemana = (inicio.getUTCDay() + 6) % 7;

    const slots = await this.prisma.venueSlot.findMany({ where: { venueId, weekday: diaSemana } });
    const reservas = await this.prisma.booking.findMany({
      where: {
        venueSlotId: { in: slots.map((s) => s.id) },
        date: { gte: inicio, lt: fim },
        status: { in: ['pending', 'confirmed'] },
      },
    });
    const ocupados = new Set(reservas.map((r) => r.venueSlotId));

    return slots.map((s) => ({ ...s, ocupado: ocupados.has(s.id) }));
  }

  async reservar(venueId: string, slotId: string, userId: string, dto: CreateBookingDto) {
    const slot = await this.prisma.venueSlot.findUnique({ where: { id: slotId } });
    if (!slot || slot.venueId !== venueId) throw new NotFoundException('Horário não encontrado.');

    const inicio = inicioDoDia(dto.date);
    const fim = fimDoDia(inicio);

    const conflito = await this.prisma.booking.findFirst({
      where: { venueSlotId: slotId, date: { gte: inicio, lt: fim }, status: { in: ['pending', 'confirmed'] } },
    });
    if (conflito) throw new ConflictException('Esse horário já está reservado nessa data.');

    return this.prisma.booking.create({
      data: { venueSlotId: slotId, bookedById: userId, date: inicio, status: 'pending' },
    });
  }

  minhasReservas(userId: string) {
    return this.prisma.booking.findMany({
      where: { bookedById: userId },
      include: { venueSlot: { include: { venue: true } } },
      orderBy: { date: 'desc' },
    });
  }

  async atualizarStatusReserva(bookingId: string, userId: string, dto: UpdateBookingStatusDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { venueSlot: { include: { venue: true } } },
    });
    if (!booking) throw new NotFoundException('Reserva não encontrada.');
    if (booking.venueSlot.venue.ownerId !== userId) {
      throw new ForbiddenException('Você não é o dono dessa quadra.');
    }
    return this.prisma.booking.update({ where: { id: bookingId }, data: { status: dto.status } });
  }

  async cancelarMinhaReserva(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({ where: { id: bookingId } });
    if (!booking) throw new NotFoundException('Reserva não encontrada.');
    if (booking.bookedById !== userId) throw new ForbiddenException('Essa reserva não é sua.');
    return this.prisma.booking.update({ where: { id: bookingId }, data: { status: 'cancelled' } });
  }

  private async exigirDono(venueId: string, userId: string) {
    const venue = await this.prisma.venue.findUnique({ where: { id: venueId } });
    if (!venue) throw new NotFoundException('Quadra não encontrada.');
    if (venue.ownerId !== userId) throw new ForbiddenException('Você não é o dono dessa quadra.');
    return venue;
  }
}

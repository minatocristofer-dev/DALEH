import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { CreateSlotDto } from './dto/create-slot.dto';
import { CreateBlockedDateDto } from './dto/create-blocked-date.dto';
import { Prisma } from '@prisma/client';
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
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

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

  // Bloqueio de data — só o dono da quadra gerencia (ver authorization em
  // `exigirDono`). O jogador nunca chama esses métodos, só enxerga o
  // resultado em `disponibilidade`.
  async bloquearData(venueId: string, userId: string, dto: CreateBlockedDateDto) {
    await this.exigirDono(venueId, userId);
    const data = inicioDoDia(dto.date);
    try {
      return await this.prisma.venueBlockedDate.create({
        data: { venueId, date: data, reason: dto.reason },
      });
    } catch (erro) {
      if (erro instanceof Prisma.PrismaClientKnownRequestError && erro.code === 'P2002') {
        throw new ConflictException('Essa data já está bloqueada.');
      }
      throw erro;
    }
  }

  async desbloquearData(venueId: string, bloqueioId: string, userId: string) {
    await this.exigirDono(venueId, userId);
    const bloqueio = await this.prisma.venueBlockedDate.findUnique({ where: { id: bloqueioId } });
    if (!bloqueio || bloqueio.venueId !== venueId) throw new NotFoundException('Bloqueio não encontrado.');
    await this.prisma.venueBlockedDate.delete({ where: { id: bloqueioId } });
    return { removido: true };
  }

  async listarBloqueios(venueId: string, userId: string) {
    await this.exigirDono(venueId, userId);
    return this.prisma.venueBlockedDate.findMany({ where: { venueId }, orderBy: { date: 'asc' } });
  }

  async disponibilidade(venueId: string, dateStr: string) {
    await this.obterQuadra(venueId);

    const inicio = inicioDoDia(dateStr);
    const fim = fimDoDia(inicio);

    // Data bloqueada pelo dono (feriado, manutenção) — nenhum horário
    // disponível nesse dia, sem precisar listar slot por slot.
    const bloqueado = await this.prisma.venueBlockedDate.findUnique({
      where: { venueId_date: { venueId, date: inicio } },
    });
    if (bloqueado) return [];

    // 0=Segunda...6=Domingo (padrão do schema); Date.getUTCDay() é 0=Domingo...6=Sábado.
    const diaSemana = (inicio.getUTCDay() + 6) % 7;

    const slots = await this.prisma.venueSlot.findMany({ where: { venueId, weekday: diaSemana } });
    const slotIds = slots.map((s) => s.id);
    const [reservas, fixos] = await Promise.all([
      this.prisma.booking.findMany({
        where: { venueSlotId: { in: slotIds }, date: { gte: inicio, lt: fim }, status: { in: ['pending', 'confirmed'] } },
      }),
      // Horário fixo (recorrente): uma vez marcado pelo dono, bloqueia esse
      // mesmo dia-da-semana/horário em QUALQUER data futura, não só na data
      // original da reserva que virou fixa — por isso essa consulta não
      // filtra por `date`, só pelo slot (o weekday já está implícito nos
      // `slotIds`, todos do mesmo dia-da-semana).
      this.prisma.booking.findMany({
        where: { venueSlotId: { in: slotIds }, isFixed: true, status: { in: ['pending', 'confirmed'] }, date: { lte: inicio } },
      }),
    ]);
    const fixoPorSlot = new Map(fixos.map((f) => [f.venueSlotId, f]));
    const reservaPorSlot = new Map(reservas.map((r) => [r.venueSlotId, r]));

    // Nome de quem reservou (pra Agenda do Locador mostrar "RESERVADO —
    // Fulano"); fixedTeamName já é o nome pronto pro horário fixo, não
    // precisa resolver usuário nenhum nesse caso.
    const idsLocatarios = reservas.filter((r) => !fixoPorSlot.has(r.venueSlotId)).map((r) => r.bookedById);
    const usuarios = idsLocatarios.length
      ? await this.prisma.user.findMany({ where: { id: { in: idsLocatarios } }, select: { id: true, fullName: true } })
      : [];
    const nomePorUserId = new Map(usuarios.map((u) => [u.id, u.fullName]));

    return slots.map((s) => {
      const fixo = fixoPorSlot.get(s.id);
      const reserva = reservaPorSlot.get(s.id);
      // O horário fixo tem prioridade na exibição sobre uma reserva pontual
      // do mesmo dia (não deveria coexistir na prática, mas se coexistir, o
      // fixo é a regra "permanente").
      const bookingAtivo = fixo ?? reserva;
      return {
        ...s,
        ocupado: Boolean(fixo) || Boolean(reserva),
        fixo: Boolean(fixo),
        fixedTeamName: fixo?.fixedTeamName ?? null,
        bookingId: bookingAtivo?.id ?? null,
        reservadoPorNome: fixo ? fixo.fixedTeamName : reserva ? (nomePorUserId.get(reserva.bookedById) ?? null) : null,
      };
    });
  }

  async reservar(venueId: string, slotId: string, userId: string, dto: CreateBookingDto) {
    const slot = await this.prisma.venueSlot.findUnique({ where: { id: slotId }, include: { venue: true } });
    if (!slot || slot.venueId !== venueId) throw new NotFoundException('Horário não encontrado.');

    const inicio = inicioDoDia(dto.date);
    const fim = fimDoDia(inicio);

    const conflito = await this.prisma.booking.findFirst({
      where: { venueSlotId: slotId, date: { gte: inicio, lt: fim }, status: { in: ['pending', 'confirmed'] } },
    });
    if (conflito) throw new ConflictException('Esse horário já está reservado nessa data.');

    const reserva = await this.prisma.booking.create({
      data: { venueSlotId: slotId, bookedById: userId, date: inicio, status: 'pending' },
    });

    // Melhor-esforço, fora do caminho principal — avisa o dono da quadra.
    await this.notifications.notificar(
      slot.venue.ownerId,
      'booking_created',
      { bookingId: reserva.id, venueId },
      'Nova reserva',
      `Você recebeu uma nova reserva na quadra ${slot.venue.name}.`,
    );

    return reserva;
  }

  minhasReservas(userId: string) {
    return this.prisma.booking.findMany({
      where: { bookedById: userId },
      include: { venueSlot: { include: { venue: true } } },
      orderBy: { date: 'desc' },
    });
  }

  // Reservas recebidas nas quadras do dono. Booking.bookedById não é uma
  // relação Prisma de verdade (é uma string solta — ver comentário no
  // schema), então o nome de quem reservou é resolvido numa segunda consulta,
  // sem criar nenhum campo ou relacionamento novo no modelo.
  async reservasDaQuadra(venueId: string, userId: string) {
    await this.exigirDono(venueId, userId);

    const reservas = await this.prisma.booking.findMany({
      where: { venueSlot: { venueId } },
      include: { venueSlot: { include: { venue: true } } },
      orderBy: { date: 'desc' },
    });

    const idsDosLocatarios = Array.from(new Set(reservas.map((r) => r.bookedById)));
    const locatarios = await this.prisma.user.findMany({
      where: { id: { in: idsDosLocatarios } },
      select: { id: true, fullName: true, avatarUrl: true },
    });
    const locatarioPorId = new Map(locatarios.map((u) => [u.id, u]));

    return reservas.map((r) => ({ ...r, bookedByUser: locatarioPorId.get(r.bookedById) ?? null }));
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
    const atualizada = await this.prisma.booking.update({ where: { id: bookingId }, data: { status: dto.status } });

    // Melhor-esforço, fora do caminho principal — avisa quem reservou.
    const confirmada = dto.status === 'confirmed';
    await this.notifications.notificar(
      booking.bookedById,
      confirmada ? 'booking_confirmed' : 'booking_cancelled_by_owner',
      { bookingId },
      confirmada ? 'Reserva confirmada' : 'Reserva cancelada',
      confirmada
        ? `Sua reserva na quadra ${booking.venueSlot.venue.name} foi confirmada.`
        : `Sua reserva na quadra ${booking.venueSlot.venue.name} foi cancelada pelo dono.`,
    );

    return atualizada;
  }

  // Marca/desmarca uma reserva como horário fixo (recorrente) — só o dono
  // da quadra pode. Não é pagamento confirmado, só uma regra de
  // recorrência (ver comentário no schema, campo `Booking.isFixed`).
  async marcarComoFixo(bookingId: string, userId: string, isFixed: boolean, fixedTeamName?: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { venueSlot: { include: { venue: true } } },
    });
    if (!booking) throw new NotFoundException('Reserva não encontrada.');
    if (booking.venueSlot.venue.ownerId !== userId) {
      throw new ForbiddenException('Você não é o dono dessa quadra.');
    }
    return this.prisma.booking.update({
      where: { id: bookingId },
      data: { isFixed, fixedTeamName: isFixed ? (fixedTeamName ?? null) : null },
    });
  }

  // Painel do Locador (QA Round 2, Priority 4) — ocupação, valores em
  // reservas e times mais frequentes, tudo agregado do que já existe.
  async dashboard(venueId: string, userId: string) {
    await this.exigirDono(venueId, userId);

    const hoje = new Date();
    const inicioHoje = new Date(Date.UTC(hoje.getUTCFullYear(), hoje.getUTCMonth(), hoje.getUTCDate()));
    const fimHoje = fimDoDia(inicioHoje);
    const inicioMes = new Date(Date.UTC(hoje.getUTCFullYear(), hoje.getUTCMonth(), 1));
    const fimMes = new Date(Date.UTC(hoje.getUTCFullYear(), hoje.getUTCMonth() + 1, 1));

    const slots = await this.prisma.venueSlot.findMany({ where: { venueId } });
    const slotIds = slots.map((s) => s.id);
    const precoPorSlot = new Map(slots.map((s) => [s.id, s.price]));

    const [reservasHoje, reservasMes] = await Promise.all([
      this.prisma.booking.findMany({
        where: { venueSlotId: { in: slotIds }, date: { gte: inicioHoje, lt: fimHoje }, status: { in: ['pending', 'confirmed'] } },
      }),
      this.prisma.booking.findMany({
        where: { venueSlotId: { in: slotIds }, date: { gte: inicioMes, lt: fimMes }, status: { in: ['pending', 'confirmed'] } },
      }),
    ]);

    const valorDoDia = reservasHoje.reduce((soma, r) => soma + (precoPorSlot.get(r.venueSlotId) ?? 0), 0);
    const valorDoMes = reservasMes.reduce((soma, r) => soma + (precoPorSlot.get(r.venueSlotId) ?? 0), 0);

    // Índice de ocupação do mês: quantos slot-dias possíveis no mês (1 slot
    // × 1 dia-da-semana × semanas do mês) de fato têm reserva — estimativa
    // simples (4 ocorrências por dia-da-semana no mês), não um calendário
    // exato com feriados/bloqueios.
    const slotsPossiveisNoMes = slots.length * 4;
    const indiceOcupacaoMes = slotsPossiveisNoMes > 0 ? Math.round((reservasMes.length / slotsPossiveisNoMes) * 100) : 0;

    // Time mais frequente — resolvido por nome do locatário (bookedById é
    // string solta, não FK; pode ser usuário OU, no caso de horário fixo, o
    // nome do time gravado em `fixedTeamName`). Só conta reservas
    // confirmadas/pendentes do mês.
    const contagemPorNome = new Map<string, number>();
    for (const r of reservasMes) {
      if (r.fixedTeamName) {
        contagemPorNome.set(r.fixedTeamName, (contagemPorNome.get(r.fixedTeamName) ?? 0) + 1);
      }
    }
    if (contagemPorNome.size === 0) {
      const idsLocatarios = Array.from(new Set(reservasMes.map((r) => r.bookedById)));
      const usuarios = await this.prisma.user.findMany({ where: { id: { in: idsLocatarios } }, select: { id: true, fullName: true } });
      const nomePorId = new Map(usuarios.map((u) => [u.id, u.fullName]));
      for (const r of reservasMes) {
        const nome = nomePorId.get(r.bookedById);
        if (nome) contagemPorNome.set(nome, (contagemPorNome.get(nome) ?? 0) + 1);
      }
    }
    let timeMaisFrequente: { nome: string; reservas: number } | null = null;
    for (const [nome, qtd] of contagemPorNome) {
      if (!timeMaisFrequente || qtd > timeMaisFrequente.reservas) timeMaisFrequente = { nome, reservas: qtd };
    }

    return {
      horariosDisponiveisHoje: Math.max(0, slots.filter((s) => s.weekday === (inicioHoje.getUTCDay() + 6) % 7).length - reservasHoje.length),
      reservasHoje: reservasHoje.length,
      reservasMes: reservasMes.length,
      valorEmReservasHoje: valorDoDia,
      valorEmReservasMes: valorDoMes,
      indiceOcupacaoMes,
      timeMaisFrequente,
    };
  }

  async cancelarMinhaReserva(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { venueSlot: { include: { venue: true } } },
    });
    if (!booking) throw new NotFoundException('Reserva não encontrada.');
    if (booking.bookedById !== userId) throw new ForbiddenException('Essa reserva não é sua.');
    const atualizada = await this.prisma.booking.update({ where: { id: bookingId }, data: { status: 'cancelled' } });

    // Melhor-esforço, fora do caminho principal — avisa o dono da quadra.
    const jogador = await this.prisma.user.findUnique({ where: { id: userId }, select: { fullName: true } });
    await this.notifications.notificar(
      booking.venueSlot.venue.ownerId,
      'booking_cancelled_by_renter',
      { bookingId, venueId: booking.venueSlot.venue.id },
      'Reserva cancelada',
      `${jogador?.fullName ?? 'Um usuário'} cancelou a reserva na sua quadra ${booking.venueSlot.venue.name}.`,
    );

    return atualizada;
  }

  private async exigirDono(venueId: string, userId: string) {
    const venue = await this.prisma.venue.findUnique({ where: { id: venueId } });
    if (!venue) throw new NotFoundException('Quadra não encontrada.');
    if (venue.ownerId !== userId) throw new ForbiddenException('Você não é o dono dessa quadra.');
    return venue;
  }
}

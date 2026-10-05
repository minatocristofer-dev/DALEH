import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PAPEIS_DE_GESTAO_DE_TIME, TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { DefinirPixDto } from './dto/definir-pix.dto';
import { CriarCobrancaDto } from './dto/criar-cobranca.dto';
import { MarcarPagamentoDto } from './dto/marcar-pagamento.dto';

@Injectable()
export class FinanceService {
  constructor(
    private prisma: PrismaService,
    private teamAuth: TeamAuthorizationService,
  ) {}

  async definirPix(teamId: string, userId: string, dto: DefinirPixDto) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);
    return this.prisma.team.update({
      where: { id: teamId },
      data: { pixKey: dto.pixKey.trim(), pixNome: dto.pixNome.trim() },
      select: { id: true, pixKey: true, pixNome: true },
    });
  }

  async criarCobranca(teamId: string, userId: string, dto: CriarCobrancaDto) {
    await this.teamAuth.exigirCapitaoOuDono(teamId, userId);

    const membros = await this.prisma.teamMember.findMany({
      where: { teamId, status: 'active' },
      select: { userId: true },
    });
    if (membros.length === 0) {
      throw new BadRequestException('O time não tem jogadores ativos para cobrar.');
    }

    return this.prisma.teamCharge.create({
      data: {
        teamId,
        titulo: dto.titulo.trim(),
        valor: dto.valor,
        criadoPorId: userId,
        itens: { create: membros.map((m) => ({ userId: m.userId })) },
      },
      select: { id: true, titulo: true, valor: true, criadoEm: true },
    });
  }

  async listarCobrancasDoTime(teamId: string, userId: string) {
    const time = await this.prisma.team.findUnique({ where: { id: teamId }, select: { id: true, ownerId: true, pixKey: true, pixNome: true } });
    if (!time) throw new NotFoundException('Time não encontrado.');

    const gestor = await this.ehGestor(teamId, time.ownerId, userId);
    if (!gestor) {
      const membro = await this.prisma.teamMember.findUnique({ where: { teamId_userId: { teamId, userId } } });
      if (!membro || membro.status !== 'active') {
        throw new ForbiddenException('Você não faz parte deste time.');
      }
    }

    const cobrancas = await this.prisma.teamCharge.findMany({
      where: { teamId, ...(gestor ? {} : { itens: { some: { userId } } }) },
      orderBy: { criadoEm: 'desc' },
      include: {
        itens: {
          where: gestor ? {} : { userId },
          include: { user: { select: { id: true, fullName: true, avatarUrl: true } } },
          orderBy: { user: { fullName: 'asc' } },
        },
      },
    });

    return {
      pixKey: time.pixKey,
      pixNome: time.pixNome,
      souGestor: gestor,
      cobrancas: cobrancas.map((c) => ({
        id: c.id,
        titulo: c.titulo,
        valor: c.valor,
        criadoEm: c.criadoEm,
        itens: c.itens.map((i) => ({
          userId: i.userId,
          fullName: i.user.fullName,
          avatarUrl: i.user.avatarUrl,
          pago: i.pagoEm !== null,
          pagoEm: i.pagoEm,
        })),
      })),
    };
  }

  async marcarPagamento(chargeId: string, userId: string, alvoUserId: string, dto: MarcarPagamentoDto) {
    const cobranca = await this.prisma.teamCharge.findUnique({ where: { id: chargeId }, select: { id: true, teamId: true } });
    if (!cobranca) throw new NotFoundException('Cobrança não encontrada.');
    await this.teamAuth.exigirCapitaoOuDono(cobranca.teamId, userId);

    const item = await this.prisma.teamChargeItem.findUnique({
      where: { chargeId_userId: { chargeId, userId: alvoUserId } },
    });
    if (!item) throw new NotFoundException('Este jogador não está nessa cobrança.');

    return this.prisma.teamChargeItem.update({
      where: { id: item.id },
      data: {
        pagoEm: dto.pago ? new Date() : null,
        marcadoPorId: dto.pago ? userId : null,
      },
      select: { userId: true, pagoEm: true },
    });
  }

  async minhasCobrancas(userId: string) {
    const itens = await this.prisma.teamChargeItem.findMany({
      where: { userId },
      orderBy: { charge: { criadoEm: 'desc' } },
      include: {
        charge: {
          select: {
            id: true,
            titulo: true,
            valor: true,
            criadoEm: true,
            team: { select: { id: true, name: true, pixKey: true, pixNome: true } },
          },
        },
      },
    });

    return itens.map((i) => ({
      chargeId: i.charge.id,
      titulo: i.charge.titulo,
      valor: i.charge.valor,
      criadoEm: i.charge.criadoEm,
      pago: i.pagoEm !== null,
      pagoEm: i.pagoEm,
      time: { id: i.charge.team.id, name: i.charge.team.name, pixKey: i.charge.team.pixKey, pixNome: i.charge.team.pixNome },
    }));
  }

  private async ehGestor(teamId: string, ownerId: string, userId: string): Promise<boolean> {
    if (ownerId === userId) return true;
    const membro = await this.prisma.teamMember.findUnique({ where: { teamId_userId: { teamId, userId } } });
    return !!membro && membro.status === 'active' && PAPEIS_DE_GESTAO_DE_TIME.includes(membro.papel);
  }
}

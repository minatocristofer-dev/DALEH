import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { PAPEIS_DE_GESTAO_DE_TIME, TeamAuthorizationService } from '../../common/authorization/team-authorization.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTeamChallengeDto } from './dto/create-team-challenge.dto';
import { CreateChallengeRequestDto } from './dto/create-challenge-request.dto';

// Combina a data (meia-noite) do desafio com o horário em texto ("20:00")
// num único DateTime pro Match criado a partir do aceite.
function combinarDataHora(data: Date, horaStr: string): Date {
  const [h, m] = horaStr.split(':').map((v) => parseInt(v, 10));
  const combinado = new Date(data);
  combinado.setUTCHours(Number.isFinite(h) ? h : 0, Number.isFinite(m) ? m : 0, 0, 0);
  return combinado;
}

@Injectable()
export class TeamChallengesService {
  constructor(
    private prisma: PrismaService,
    private teamAuth: TeamAuthorizationService,
    private notifications: NotificationsService,
  ) {}

  async criarDesafio(userId: string, dto: CreateTeamChallengeDto) {
    await this.teamAuth.exigirCapitaoOuDono(dto.teamId, userId);

    const modalidade = await this.prisma.modalidade.findUnique({ where: { key: dto.modalidade } });
    if (!modalidade) throw new BadRequestException('Modalidade inválida.');

    return this.prisma.teamChallenge.create({
      data: {
        teamId: dto.teamId,
        modalidadeId: modalidade.id,
        city: dto.city,
        venueId: dto.venueId,
        scheduledDate: new Date(dto.scheduledDate),
        scheduledTime: dto.scheduledTime,
        desiredLevel: dto.desiredLevel,
      },
    });
  }

  listarDesafios(city?: string, modalidade?: string) {
    return this.prisma.teamChallenge.findMany({
      where: {
        status: 'ABERTA',
        ...(city ? { city: { contains: city, mode: 'insensitive' } } : {}),
        ...(modalidade ? { modalidade: { key: modalidade as any } } : {}),
      },
      include: { team: true, modalidade: true },
      orderBy: { scheduledDate: 'asc' },
    });
  }

  async solicitar(challengeId: string, userId: string, dto: CreateChallengeRequestDto) {
    const desafio = await this.prisma.teamChallenge.findUnique({ where: { id: challengeId } });
    if (!desafio) throw new NotFoundException('Desafio não encontrado.');
    if (desafio.status !== 'ABERTA') throw new BadRequestException('Esse desafio não está mais aberto.');
    if (desafio.teamId === dto.requestingTeamId) {
      throw new BadRequestException('Seu time não pode solicitar o próprio desafio.');
    }

    await this.teamAuth.exigirCapitaoOuDono(dto.requestingTeamId, userId);

    const existente = await this.prisma.challengeRequest.findUnique({
      where: { challengeId_requestingTeamId: { challengeId, requestingTeamId: dto.requestingTeamId } },
    });
    if (existente) throw new ConflictException('Seu time já solicitou esse desafio.');

    const solicitacaoCriada = await this.prisma.challengeRequest.create({
      data: { challengeId, requestingTeamId: dto.requestingTeamId },
    });

    // Melhor-esforço, fora do caminho principal.
    const gestoresOrganizador = await this.teamAuth.obterGestoresDoTime(desafio.teamId);
    for (const destinatarioId of gestoresOrganizador) {
      await this.notifications.notificar(
        destinatarioId,
        'challenge_request_received',
        { challengeId, requestId: solicitacaoCriada.id },
        'Novo pedido de desafio',
        'Um time quer aceitar seu desafio. Dá uma olhada nas solicitações.',
      );
    }

    return solicitacaoCriada;
  }

  async aceitar(challengeId: string, requestId: string, userId: string) {
    const desafio = await this.prisma.teamChallenge.findUnique({ where: { id: challengeId } });
    if (!desafio) throw new NotFoundException('Desafio não encontrado.');
    await this.teamAuth.exigirCapitaoOuDono(desafio.teamId, userId);

    const solicitacao = await this.prisma.challengeRequest.findUnique({ where: { id: requestId } });
    if (!solicitacao || solicitacao.challengeId !== challengeId) {
      throw new NotFoundException('Solicitação não encontrada.');
    }

    // Precisamos saber quem mais tinha solicitado (pra notificar a recusa em
    // cascata) antes da transação mudar o status de todo mundo.
    const outrasSolicitacoes = await this.prisma.challengeRequest.findMany({
      where: { challengeId, id: { not: requestId } },
    });

    const { desafioAtualizado, match } = await this.prisma.$transaction(async (tx) => {
      await tx.challengeRequest.update({ where: { id: requestId }, data: { status: 'ACEITA' } });
      // Todas as outras solicitações do mesmo desafio são recusadas automaticamente —
      // evita dois times "confirmados" pro mesmo horário.
      await tx.challengeRequest.updateMany({
        where: { challengeId, id: { not: requestId } },
        data: { status: 'RECUSADA' },
      });

      // Aceitar o desafio cria o Jogo de verdade — Match com os dois times já
      // vinculados, herdando quadra/modalidade/horário do próprio desafio.
      const matchCriado = await tx.match.create({
        data: {
          createdById: userId,
          venueId: desafio.venueId,
          modalidadeId: desafio.modalidadeId,
          homeTeamId: desafio.teamId,
          awayTeamId: solicitacao.requestingTeamId,
          scheduledAt: combinarDataHora(desafio.scheduledDate, desafio.scheduledTime),
          visibility: 'public',
        },
      });

      const teamChallengeAtualizado = await tx.teamChallenge.update({
        where: { id: challengeId },
        data: { status: 'CONFIRMADA', opponentTeamId: solicitacao.requestingTeamId, matchId: matchCriado.id },
      });

      return { desafioAtualizado: teamChallengeAtualizado, match: matchCriado };
    });

    // Notificações, melhor-esforço, fora da transação.
    const gestoresEnvolvidos = [
      ...(await this.teamAuth.obterGestoresDoTime(desafio.teamId)),
      ...(await this.teamAuth.obterGestoresDoTime(solicitacao.requestingTeamId)),
    ];
    for (const destinatarioId of gestoresEnvolvidos) {
      await this.notifications.notificar(
        destinatarioId,
        'challenge_accepted',
        { challengeId, matchId: match.id },
        'Desafio confirmado',
        'Seu desafio foi confirmado! A partida já está marcada.',
      );
    }

    for (const outra of outrasSolicitacoes) {
      const gestoresRecusados = await this.teamAuth.obterGestoresDoTime(outra.requestingTeamId);
      for (const destinatarioId of gestoresRecusados) {
        await this.notifications.notificar(
          destinatarioId,
          'challenge_request_declined',
          { challengeId },
          'Solicitação recusada',
          'Sua solicitação pra esse desafio foi recusada — o organizador confirmou com outro time.',
        );
      }
    }

    return desafioAtualizado;
  }

  async meusDesafios(userId: string) {
    const meusTimesIds = await this.idsDosMeusTimes(userId);

    const comoOrganizador = await this.prisma.teamChallenge.findMany({
      where: { teamId: { in: meusTimesIds } },
      include: { requests: { include: { requestingTeam: true } } },
      orderBy: { scheduledDate: 'asc' },
    });

    const minhasSolicitacoes = await this.prisma.challengeRequest.findMany({
      where: { requestingTeamId: { in: meusTimesIds } },
      include: { challenge: { include: { team: true } } },
      orderBy: { createdAt: 'desc' },
    });

    return { comoOrganizador, minhasSolicitacoes };
  }

  private async idsDosMeusTimes(userId: string): Promise<string[]> {
    const [times, membros] = await Promise.all([
      this.prisma.team.findMany({ where: { ownerId: userId }, select: { id: true } }),
      this.prisma.teamMember.findMany({
        where: { userId, status: 'active', papel: { in: PAPEIS_DE_GESTAO_DE_TIME as any } },
        select: { teamId: true },
      }),
    ]);
    return Array.from(new Set([...times.map((t) => t.id), ...membros.map((m) => m.teamId)]));
  }
}

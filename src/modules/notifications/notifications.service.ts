import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { FcmService } from './fcm.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private fcm: FcmService,
  ) {}

  listarMinhas(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async marcarLida(id: string, userId: string) {
    const notificacao = await this.prisma.notification.findUnique({ where: { id } });
    if (!notificacao) throw new NotFoundException('Notificação não encontrada.');
    if (notificacao.userId !== userId) throw new ForbiddenException('Essa notificação não é sua.');

    return this.prisma.notification.update({ where: { id }, data: { readAt: new Date() } });
  }

  registrarToken(userId: string, dto: RegisterDeviceTokenDto) {
    return this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      create: { userId, token: dto.token, platform: dto.platform },
      update: { userId, platform: dto.platform },
    });
  }

  // Usado pelos outros módulos (ex: convocação de time) — grava a notificação
  // in-app e, se o Firebase estiver configurado, também dispara o push real.
  async notificar(userId: string, type: string, payload: Prisma.InputJsonValue, titulo: string, corpo: string) {
    const notificacao = await this.prisma.notification.create({ data: { userId, type, payload } });

    if (this.fcm.ativo) {
      const tokens = await this.prisma.deviceToken.findMany({ where: { userId }, select: { token: true } });
      await this.fcm.enviarParaTokens(
        tokens.map((t) => t.token),
        titulo,
        corpo,
        { type, notificationId: notificacao.id },
      );
    }

    return notificacao;
  }
}

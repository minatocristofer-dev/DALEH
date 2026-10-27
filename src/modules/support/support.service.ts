import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';

// Fale Conosco — mensagem mínima, sem sistema de tickets completo (sem
// status, sem resposta in-app). Revisão é feita direto no banco/painel.
@Injectable()
export class SupportService {
  constructor(private prisma: PrismaService) {}

  async criar(userId: string, dto: CreateSupportTicketDto) {
    return this.prisma.supportTicket.create({
      data: {
        userId,
        category: dto.category,
        subject: dto.subject,
        message: dto.message,
        platform: dto.platform,
        appVersion: dto.appVersion,
      },
    });
  }
}

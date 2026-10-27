import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { SupportService } from './support.service';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';

@Controller('support')
@UseGuards(AuthGuard('jwt'))
export class SupportController {
  constructor(private supportService: SupportService) {}

  // POST /v1/support/tickets — "Fale Conosco" (Perfil > Configurações).
  @Post('tickets')
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateSupportTicketDto) {
    return this.supportService.criar(user.id, dto);
  }
}

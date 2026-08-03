import { Body, Controller, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { TeamsService } from './teams.service';
import { RespondCallUpDto } from './dto/respond-call-up.dto';

@Controller('call-ups')
@UseGuards(AuthGuard('jwt'))
export class CallUpsController {
  constructor(private teamsService: TeamsService) {}

  @Get('mine')
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.minhasConvocacoes(user.id);
  }

  @Patch(':id/respond')
  responder(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: RespondCallUpDto) {
    return this.teamsService.responderConvocacao(id, user.id, dto);
  }
}

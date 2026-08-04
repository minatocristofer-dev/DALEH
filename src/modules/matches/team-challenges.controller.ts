import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { TeamChallengesService } from './team-challenges.service';
import { CreateTeamChallengeDto } from './dto/create-team-challenge.dto';
import { CreateChallengeRequestDto } from './dto/create-challenge-request.dto';

@Controller('team-challenges')
@UseGuards(AuthGuard('jwt'))
export class TeamChallengesController {
  constructor(private teamChallengesService: TeamChallengesService) {}

  @Post()
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateTeamChallengeDto) {
    return this.teamChallengesService.criarDesafio(user.id, dto);
  }

  @Get()
  listar(@Query('city') city?: string, @Query('modalidade') modalidade?: string) {
    return this.teamChallengesService.listarDesafios(city, modalidade);
  }

  @Get('mine')
  meus(@CurrentUser() user: UsuarioAutenticado) {
    return this.teamChallengesService.meusDesafios(user.id);
  }

  @Post(':id/requests')
  solicitar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateChallengeRequestDto) {
    return this.teamChallengesService.solicitar(id, user.id, dto);
  }

  @Post(':id/requests/:requestId/accept')
  aceitar(@Param('id') id: string, @Param('requestId') requestId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.teamChallengesService.aceitar(id, requestId, user.id);
  }
}

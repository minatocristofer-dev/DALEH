import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { TeamsService } from './teams.service';
import { CreateTeamDto } from './dto/create-team.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';
import { CreateCallUpDto } from './dto/create-call-up.dto';

@Controller('teams')
@UseGuards(AuthGuard('jwt'))
export class TeamsController {
  constructor(private teamsService: TeamsService) {}

  @Post()
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateTeamDto) {
    return this.teamsService.criarTime(user.id, dto);
  }

  @Get('mine')
  meusTimes(@CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.listarMeusTimes(user.id);
  }

  @Get(':id')
  detalhe(@Param('id') id: string) {
    return this.teamsService.obterTime(id);
  }

  @Post(':id/members')
  adicionarMembro(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: AddMemberDto) {
    return this.teamsService.adicionarMembro(id, user.id, dto);
  }

  @Patch(':id/members/:userId')
  atualizarMembro(
    @Param('id') id: string,
    @Param('userId') alvoUserId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: UpdateMemberDto,
  ) {
    return this.teamsService.atualizarMembro(id, alvoUserId, user.id, dto);
  }

  @Delete(':id/members/:userId')
  removerMembro(@Param('id') id: string, @Param('userId') alvoUserId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.removerMembro(id, alvoUserId, user.id);
  }

  @Post(':id/call-ups')
  convocar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateCallUpDto) {
    return this.teamsService.convocar(id, user.id, dto);
  }

  @Get(':id/call-ups')
  convocacoesDoTime(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.teamsService.listarConvocacoesDoTime(id, user.id);
  }
}

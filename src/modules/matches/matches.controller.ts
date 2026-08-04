import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { MatchesService } from './matches.service';
import { CreateMatchDto } from './dto/create-match.dto';
import { UpdateMatchStatusDto } from './dto/update-match-status.dto';
import { CreateEventDto } from './dto/create-event.dto';

@Controller('matches')
@UseGuards(AuthGuard('jwt'))
export class MatchesController {
  constructor(private matchesService: MatchesService) {}

  @Post()
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateMatchDto) {
    return this.matchesService.criarPartida(user.id, dto);
  }

  @Get()
  listar(@Query('status') status?: string) {
    return this.matchesService.listarPartidas(status);
  }

  @Get('mine')
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.minhasPartidas(user.id);
  }

  @Get(':id')
  detalhe(@Param('id') id: string) {
    return this.matchesService.obterPartida(id);
  }

  @Patch(':id/status')
  atualizarStatus(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateMatchStatusDto) {
    return this.matchesService.atualizarStatus(id, user.id, dto);
  }

  @Post(':id/attendance')
  confirmarPresenca(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.confirmarPresenca(id, user.id);
  }

  @Delete(':id/attendance')
  cancelarPresenca(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.cancelarPresenca(id, user.id);
  }

  @Post(':id/events')
  registrarEvento(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateEventDto) {
    return this.matchesService.registrarEvento(id, user.id, dto);
  }
}

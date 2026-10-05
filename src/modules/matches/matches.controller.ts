import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { OptionalAuthGuard } from '../../common/guards/optional-auth.guard';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { MatchesService } from './matches.service';
import { CreateMatchDto } from './dto/create-match.dto';
import { UpdateMatchStatusDto } from './dto/update-match-status.dto';
import { CreateEventDto } from './dto/create-event.dto';
import { RegisterGoalDto } from './dto/register-goal.dto';
import { ElectMvpDto } from './dto/elect-mvp.dto';
import { MarcarPagamentoDto } from './dto/marcar-pagamento.dto';
import { DefinirValorQuadraDto } from './dto/definir-valor-quadra.dto';

// Explorar jogos públicos não exige login (mesmo padrão de Venues, Fase 0.5)
// — só listar/detalhe são públicos; toda ação (criar, participar, etc.)
// continua exigindo JWT, aplicado rota a rota.
@Controller('matches')
export class MatchesController {
  constructor(private matchesService: MatchesService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateMatchDto) {
    return this.matchesService.criarPartida(user.id, dto);
  }

  @Get()
  @UseGuards(OptionalAuthGuard)
  listar(@Query('status') status?: string) {
    return this.matchesService.listarPartidas(status);
  }

  @Get('mine')
  @UseGuards(AuthGuard('jwt'))
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.minhasPartidas(user.id);
  }

  @Get(':id')
  @UseGuards(OptionalAuthGuard)
  detalhe(@Param('id') id: string, @CurrentUser() user?: UsuarioAutenticado) {
    return this.matchesService.obterPartida(id, user?.id);
  }

  @Patch(':id/status')
  @UseGuards(AuthGuard('jwt'))
  atualizarStatus(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateMatchStatusDto) {
    return this.matchesService.atualizarStatus(id, user.id, dto);
  }

  @Post(':id/attendance')
  @UseGuards(AuthGuard('jwt'))
  confirmarPresenca(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.confirmarPresenca(id, user.id);
  }

  @Delete(':id/attendance')
  @UseGuards(AuthGuard('jwt'))
  cancelarPresenca(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.matchesService.cancelarPresenca(id, user.id);
  }

  @Post(':id/events')
  @UseGuards(AuthGuard('jwt'))
  registrarEvento(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateEventDto) {
    return this.matchesService.registrarEvento(id, user.id, dto);
  }

  // Súmula digital (Fase 8) — só capitão/dono de um dos dois times da
  // partida pode registrar gol/eleger MVP; validado inteiramente no service.
  @Post(':id/goals')
  @UseGuards(AuthGuard('jwt'))
  registrarGol(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: RegisterGoalDto) {
    return this.matchesService.registrarGol(id, user.id, dto);
  }

  @Post(':id/mvp')
  @UseGuards(AuthGuard('jwt'))
  elegerMvp(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: ElectMvpDto) {
    return this.matchesService.elegerMvp(id, user.id, dto);
  }

  @Patch(':id/attendance/:userId/pagamento')
  @UseGuards(AuthGuard('jwt'))
  marcarPagamento(
    @Param('id') id: string,
    @Param('userId') alvoUserId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: MarcarPagamentoDto,
  ) {
    return this.matchesService.marcarPagamento(id, user.id, alvoUserId, dto);
  }

  @Patch(':id/valor-quadra')
  @UseGuards(AuthGuard('jwt'))
  definirValorQuadra(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: DefinirValorQuadraDto) {
    return this.matchesService.definirValorQuadra(id, user.id, dto.valor);
  }
}

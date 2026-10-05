import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { FinanceService } from './finance.service';
import { DefinirPixDto } from './dto/definir-pix.dto';
import { CriarCobrancaDto } from './dto/criar-cobranca.dto';
import { MarcarPagamentoDto } from './dto/marcar-pagamento.dto';

@Controller('finance')
@UseGuards(AuthGuard('jwt'))
export class FinanceController {
  constructor(private finance: FinanceService) {}

  @Patch('teams/:teamId/pix')
  definirPix(@Param('teamId') teamId: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: DefinirPixDto) {
    return this.finance.definirPix(teamId, user.id, dto);
  }

  @Post('teams/:teamId/charges')
  criarCobranca(@Param('teamId') teamId: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CriarCobrancaDto) {
    return this.finance.criarCobranca(teamId, user.id, dto);
  }

  @Get('teams/:teamId/charges')
  listarCobrancas(@Param('teamId') teamId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.finance.listarCobrancasDoTime(teamId, user.id);
  }

  @Patch('charges/:chargeId/items/:userId')
  marcarPagamento(
    @Param('chargeId') chargeId: string,
    @Param('userId') alvoUserId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: MarcarPagamentoDto,
  ) {
    return this.finance.marcarPagamento(chargeId, user.id, alvoUserId, dto);
  }

  @Get('mine')
  minhasCobrancas(@CurrentUser() user: UsuarioAutenticado) {
    return this.finance.minhasCobrancas(user.id);
  }
}

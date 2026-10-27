import { Body, Controller, Delete, Get, Param, Patch, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { VenuesService } from './venues.service';
import { UpdateBookingStatusDto } from './dto/update-booking-status.dto';
import { UpdateBookingFixedDto } from './dto/update-booking-fixed.dto';

@Controller('bookings')
@UseGuards(AuthGuard('jwt'))
export class BookingsController {
  constructor(private venuesService: VenuesService) {}

  @Get('mine')
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.minhasReservas(user.id);
  }

  @Patch(':id/status')
  atualizarStatus(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateBookingStatusDto) {
    return this.venuesService.atualizarStatusReserva(id, user.id, dto);
  }

  @Delete(':id')
  cancelar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.cancelarMinhaReserva(id, user.id);
  }

  // Horário fixo (recorrente) — só o dono da quadra marca/desmarca.
  @Patch(':id/fixed')
  marcarComoFixo(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateBookingFixedDto) {
    return this.venuesService.marcarComoFixo(id, user.id, dto.isFixed, dto.fixedTeamName);
  }
}

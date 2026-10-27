import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { VenuesService } from './venues.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { CreateSlotDto } from './dto/create-slot.dto';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateBlockedDateDto } from './dto/create-blocked-date.dto';

// Visualizar/explorar quadras é público (não exige login): listar, detalhe e
// disponibilidade. Só ações que alteram estado (criar/editar quadra, slots,
// reservar) exigem JWT — por isso o guard é aplicado por rota, não na classe.
@Controller('venues')
export class VenuesController {
  constructor(private venuesService: VenuesService) {}

  @Post()
  @UseGuards(AuthGuard('jwt'))
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateVenueDto) {
    return this.venuesService.criarQuadra(user.id, dto);
  }

  @Get()
  listar(@Query('city') city?: string) {
    return this.venuesService.listarQuadras(city);
  }

  @Get('mine')
  @UseGuards(AuthGuard('jwt'))
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.minhasQuadras(user.id);
  }

  @Get(':id')
  detalhe(@Param('id') id: string) {
    return this.venuesService.obterQuadra(id);
  }

  @Patch(':id')
  @UseGuards(AuthGuard('jwt'))
  editar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateVenueDto) {
    return this.venuesService.editarQuadra(id, user.id, dto);
  }

  @Post(':id/slots')
  @UseGuards(AuthGuard('jwt'))
  criarSlot(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateSlotDto) {
    return this.venuesService.criarSlot(id, user.id, dto);
  }

  @Delete(':id/slots/:slotId')
  @UseGuards(AuthGuard('jwt'))
  removerSlot(@Param('id') id: string, @Param('slotId') slotId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.removerSlot(id, slotId, user.id);
  }

  @Get(':id/availability')
  disponibilidade(@Param('id') id: string, @Query('date') date: string) {
    return this.venuesService.disponibilidade(id, date);
  }

  @Post(':id/blocked-dates')
  @UseGuards(AuthGuard('jwt'))
  bloquearData(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateBlockedDateDto) {
    return this.venuesService.bloquearData(id, user.id, dto);
  }

  @Get(':id/blocked-dates')
  @UseGuards(AuthGuard('jwt'))
  listarBloqueios(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.listarBloqueios(id, user.id);
  }

  @Delete(':id/blocked-dates/:blockedId')
  @UseGuards(AuthGuard('jwt'))
  desbloquearData(
    @Param('id') id: string,
    @Param('blockedId') blockedId: string,
    @CurrentUser() user: UsuarioAutenticado,
  ) {
    return this.venuesService.desbloquearData(id, blockedId, user.id);
  }

  @Get(':id/bookings')
  @UseGuards(AuthGuard('jwt'))
  reservasDaQuadra(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.reservasDaQuadra(id, user.id);
  }

  // Painel do Locador (calendário + dashboard, QA Round 2 Priority 4).
  @Get(':id/dashboard')
  @UseGuards(AuthGuard('jwt'))
  dashboard(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.dashboard(id, user.id);
  }

  @Post(':id/slots/:slotId/bookings')
  @UseGuards(AuthGuard('jwt'))
  reservar(
    @Param('id') id: string,
    @Param('slotId') slotId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: CreateBookingDto,
  ) {
    return this.venuesService.reservar(id, slotId, user.id, dto);
  }
}

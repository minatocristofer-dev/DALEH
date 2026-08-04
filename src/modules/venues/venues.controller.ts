import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { VenuesService } from './venues.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { CreateSlotDto } from './dto/create-slot.dto';
import { CreateBookingDto } from './dto/create-booking.dto';

@Controller('venues')
@UseGuards(AuthGuard('jwt'))
export class VenuesController {
  constructor(private venuesService: VenuesService) {}

  @Post()
  criar(@CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateVenueDto) {
    return this.venuesService.criarQuadra(user.id, dto);
  }

  @Get()
  listar(@Query('city') city?: string) {
    return this.venuesService.listarQuadras(city);
  }

  @Get('mine')
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.minhasQuadras(user.id);
  }

  @Get(':id')
  detalhe(@Param('id') id: string) {
    return this.venuesService.obterQuadra(id);
  }

  @Patch(':id')
  editar(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateVenueDto) {
    return this.venuesService.editarQuadra(id, user.id, dto);
  }

  @Post(':id/slots')
  criarSlot(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado, @Body() dto: CreateSlotDto) {
    return this.venuesService.criarSlot(id, user.id, dto);
  }

  @Delete(':id/slots/:slotId')
  removerSlot(@Param('id') id: string, @Param('slotId') slotId: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.venuesService.removerSlot(id, slotId, user.id);
  }

  @Get(':id/availability')
  disponibilidade(@Param('id') id: string, @Query('date') date: string) {
    return this.venuesService.disponibilidade(id, date);
  }

  @Post(':id/slots/:slotId/bookings')
  reservar(
    @Param('id') id: string,
    @Param('slotId') slotId: string,
    @CurrentUser() user: UsuarioAutenticado,
    @Body() dto: CreateBookingDto,
  ) {
    return this.venuesService.reservar(id, slotId, user.id, dto);
  }
}

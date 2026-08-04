import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@Controller('notifications')
@UseGuards(AuthGuard('jwt'))
export class NotificationsController {
  constructor(private notificationsService: NotificationsService) {}

  @Get('mine')
  minhas(@CurrentUser() user: UsuarioAutenticado) {
    return this.notificationsService.listarMinhas(user.id);
  }

  @Patch(':id/read')
  marcarLida(@Param('id') id: string, @CurrentUser() user: UsuarioAutenticado) {
    return this.notificationsService.marcarLida(id, user.id);
  }

  @Post('device-token')
  registrarToken(@CurrentUser() user: UsuarioAutenticado, @Body() dto: RegisterDeviceTokenDto) {
    return this.notificationsService.registrarToken(user.id, dto);
  }
}

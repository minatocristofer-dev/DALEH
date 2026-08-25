import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';

// Perfil público (Fase 7) — separado de `AuthController` (que é só ações de
// autenticação) porque `/users/:id` é um recurso, não uma ação de auth.
// Qualquer usuário autenticado pode ver o perfil de qualquer outro (decisão
// explícita desta fase — não exige time/jogo em comum, não tem sistema de
// privacidade além de nunca devolver e-mail/telefone/data de nascimento).
@Controller('users')
@UseGuards(AuthGuard('jwt'))
export class UsersController {
  constructor(private authService: AuthService) {}

  @Get(':id')
  perfilPublico(@Param('id') id: string) {
    return this.authService.perfilPublico(id);
  }
}

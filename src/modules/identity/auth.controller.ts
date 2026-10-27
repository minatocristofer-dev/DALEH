import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Patch, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { CurrentUser, UsuarioAutenticado } from '../../common/decorators/current-user.decorator';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SocialLoginDto } from './dto/social-login.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  // POST /v1/auth/register — reflete os 3 passos do cadastro do protótipo,
  // enviados de uma vez só pelo app depois que o usuário passa pelas 3 telas.
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  // Login social (Google/Apple) — o front loga via Supabase Auth e manda o
  // access_token da sessão aqui pra trocar por um JWT nosso.
  @Post('social')
  @HttpCode(HttpStatus.OK)
  social(@Body() dto: SocialLoginDto) {
    return this.authService.socialLogin(dto);
  }

  // GET /v1/auth/me — único jeito do app saber quem é o usuário logado além
  // do e-mail já presente no JWT (ver Fase 6, auditoria: não existia nenhum
  // endpoint que devolvesse os dados do próprio usuário).
  @Get('me')
  @UseGuards(AuthGuard('jwt'))
  me(@CurrentUser() user: UsuarioAutenticado) {
    return this.authService.me(user.id);
  }

  // PATCH /v1/auth/me — edição do próprio perfil (hoje só apelido).
  @Patch('me')
  @UseGuards(AuthGuard('jwt'))
  atualizarPerfil(@CurrentUser() user: UsuarioAutenticado, @Body() dto: UpdateProfileDto) {
    return this.authService.atualizarPerfil(user.id, dto);
  }

  // DELETE /v1/auth/me — exclusão da própria conta (exigência da Play
  // Store). Anonimiza em vez de apagar fisicamente — ver comentário em
  // AuthService.excluirPropriaConta.
  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(AuthGuard('jwt'))
  excluirConta(@CurrentUser() user: UsuarioAutenticado) {
    return this.authService.excluirPropriaConta(user.id);
  }
}

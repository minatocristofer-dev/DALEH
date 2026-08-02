import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SocialLoginDto } from './dto/social-login.dto';

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
}

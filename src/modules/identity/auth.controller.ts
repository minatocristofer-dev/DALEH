import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

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

  // TODO (próxima iteração): POST /auth/social (Google/Apple) —
  // depende de qual provedor de auth for escolhido (Supabase Auth, Auth0 etc),
  // conforme "Fundação técnica" no plano de implementação.
}

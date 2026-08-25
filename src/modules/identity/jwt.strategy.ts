import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

function obterSegredoOuFalhar(configService: ConfigService): string {
  const secret = configService.get<string>('JWT_SECRET');
  if (!secret) {
    throw new Error(
      'JWT_SECRET não está configurado. Defina a variável de ambiente antes de iniciar a aplicação.',
    );
  }
  return secret;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: obterSegredoOuFalhar(configService),
    });
  }

  // O retorno daqui vira "request.user" em qualquer rota protegida por @UseGuards(AuthGuard('jwt'))
  async validate(payload: { sub: string; email: string }) {
    return { id: payload.sub, email: payload.email };
  }
}

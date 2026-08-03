import { createParamDecorator, ExecutionContext } from '@nestjs/common';

// O que o JwtStrategy.validate() devolve (ver jwt.strategy.ts) — vira
// request.user em qualquer rota atrás de @UseGuards(AuthGuard('jwt')).
export interface UsuarioAutenticado {
  id: string;
  email: string;
}

export const CurrentUser = createParamDecorator((_: unknown, ctx: ExecutionContext): UsuarioAutenticado => {
  const request = ctx.switchToHttp().getRequest();
  return request.user;
});

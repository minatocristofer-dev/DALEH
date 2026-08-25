import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Igual ao AuthGuard('jwt'), mas nunca bloqueia a rota: se não vier token (ou
 * vier inválido), `request.user` só fica undefined em vez de dar 401. Usado
 * em rotas de leitura pública que precisam saber "quem é o usuário, se
 * houver" (ex: checar se uma partida privada pode ser vista).
 */
@Injectable()
export class OptionalAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser = any>(_err: unknown, user: TUser): TUser {
    return user;
  }
}

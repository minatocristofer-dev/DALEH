import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles || requiredRoles.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const userId: string | undefined = request.user?.id;
    if (!userId) return false;

    // Papel GLOBAL do usuário (ex: platform_admin). Papéis de CONTEXTO
    // (ex: "capitão do time X") precisam ser checados no próprio service,
    // comparando contextId com o recurso sendo acessado — não dá pra
    // fazer isso de forma genérica aqui sem saber o formato da rota.
    const userRoles = await this.prisma.userRole.findMany({
      where: { userId, role: { key: { in: requiredRoles } } },
    });

    return userRoles.length > 0;
  }
}

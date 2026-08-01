import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/**
 * Marca uma rota como exigindo um ou mais papéis (RBAC).
 * Uso: @Roles('team_admin') acima do método do controller.
 * O contexto (ex: "é admin DESTE time") é checado dentro do próprio
 * service/guard, comparando contextId com o :id da rota — RBAC nunca
 * deve confiar só no papel global do usuário.
 */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);

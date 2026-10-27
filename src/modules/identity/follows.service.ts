import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

// "Parças" (MVP) — seguir outro jogador, sem feed/chat. Lista devolve só o
// necessário pra um card (id, nome/apelido, foto) + abrir o perfil público.
@Injectable()
export class FollowsService {
  constructor(private prisma: PrismaService) {}

  async seguir(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('Você não pode seguir a si mesmo.');
    }
    const alvo = await this.prisma.user.findUnique({ where: { id: followingId } });
    if (!alvo) throw new NotFoundException('Jogador não encontrado.');

    // Idempotente — seguir alguém que já é seguido simplesmente não faz
    // nada de novo (evita erro de unique constraint virar 500 genérico).
    await this.prisma.playerFollow.upsert({
      where: { followerId_followingId: { followerId, followingId } },
      create: { followerId, followingId },
      update: {},
    });
  }

  async deixarDeSeguir(followerId: string, followingId: string) {
    await this.prisma.playerFollow.deleteMany({ where: { followerId, followingId } });
  }

  private async listar(where: { followerId: string } | { followingId: string }, campo: 'following' | 'follower') {
    const registros = await this.prisma.playerFollow.findMany({
      where,
      include: { [campo]: true },
      orderBy: { createdAt: 'desc' },
    });
    return registros.map((r: any) => {
      const u = r[campo];
      return { id: u.id, fullName: u.fullName, nickname: u.nickname, avatarUrl: u.avatarUrl };
    });
  }

  // Quem o próprio usuário segue.
  seguindo(userId: string) {
    return this.listar({ followerId: userId }, 'following');
  }

  // Quem segue o próprio usuário.
  seguidores(userId: string) {
    return this.listar({ followingId: userId }, 'follower');
  }
}

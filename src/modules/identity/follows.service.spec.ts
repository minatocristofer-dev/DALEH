import { BadRequestException, NotFoundException } from '@nestjs/common';
import { FollowsService } from './follows.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('FollowsService', () => {
  let prisma: any;
  let service: FollowsService;

  beforeEach(() => {
    prisma = {
      user: { findUnique: jest.fn(), findMany: jest.fn() },
      playerFollow: { upsert: jest.fn(), deleteMany: jest.fn(), findMany: jest.fn() },
    };
    service = new FollowsService(prisma as unknown as PrismaService);
  });

  describe('seguir', () => {
    it('rejeita seguir a si mesmo', async () => {
      await expect(service.seguir('user-1', 'user-1')).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.playerFollow.upsert).not.toHaveBeenCalled();
    });

    it('lança 404 quando o alvo não existe', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.seguir('user-1', 'user-inexistente')).rejects.toBeInstanceOf(NotFoundException);
    });

    it('é idempotente — seguir quem já é seguido não lança (upsert, não create)', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-2' });

      await service.seguir('user-1', 'user-2');

      expect(prisma.playerFollow.upsert).toHaveBeenCalledWith({
        where: { followerId_followingId: { followerId: 'user-1', followingId: 'user-2' } },
        create: { followerId: 'user-1', followingId: 'user-2' },
        update: {},
      });
    });
  });

  describe('deixarDeSeguir', () => {
    it('remove a relação sem lançar mesmo se ela não existir', async () => {
      await service.deixarDeSeguir('user-1', 'user-2');

      expect(prisma.playerFollow.deleteMany).toHaveBeenCalledWith({
        where: { followerId: 'user-1', followingId: 'user-2' },
      });
    });
  });

  describe('seguindo / seguidores', () => {
    it('seguindo() devolve os dados públicos de quem o usuário segue', async () => {
      prisma.playerFollow.findMany.mockResolvedValue([
        { following: { id: 'user-2', fullName: 'Gabriel Souza', nickname: 'Gabi', avatarUrl: null } },
      ]);

      const resultado = await service.seguindo('user-1');

      expect(prisma.playerFollow.findMany).toHaveBeenCalledWith({
        where: { followerId: 'user-1' },
        include: { following: true },
        orderBy: { createdAt: 'desc' },
      });
      expect(resultado).toEqual([{ id: 'user-2', fullName: 'Gabriel Souza', nickname: 'Gabi', avatarUrl: null }]);
    });

    it('seguidores() devolve os dados públicos de quem segue o usuário', async () => {
      prisma.playerFollow.findMany.mockResolvedValue([
        { follower: { id: 'user-3', fullName: 'Matheus Oliveira', nickname: null, avatarUrl: null } },
      ]);

      const resultado = await service.seguidores('user-1');

      expect(prisma.playerFollow.findMany).toHaveBeenCalledWith({
        where: { followingId: 'user-1' },
        include: { follower: true },
        orderBy: { createdAt: 'desc' },
      });
      expect(resultado).toEqual([{ id: 'user-3', fullName: 'Matheus Oliveira', nickname: null, avatarUrl: null }]);
    });
  });

  describe('buscar', () => {
    it('termo com menos de 2 caracteres devolve lista vazia sem consultar o banco', async () => {
      const resultado = await service.buscar('user-1', 'a');

      expect(resultado).toEqual([]);
      expect(prisma.user.findMany).not.toHaveBeenCalled();
    });

    it('termo com "@" busca por e-mail EXATO, nunca parcial (evita escanear a base)', async () => {
      prisma.user.findMany.mockResolvedValue([
        { id: 'user-2', fullName: 'Gabriel Souza', nickname: 'Gabi', avatarUrl: null },
      ]);
      prisma.playerFollow.findMany.mockResolvedValue([]);

      await service.buscar('user-1', 'gabriel@teste.com');

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: { email: { equals: 'gabriel@teste.com', mode: 'insensitive' }, id: { not: 'user-1' } },
        take: 20,
      });
    });

    it('termo sem "@" busca por nome OU apelido parcial, excluindo quem já foi excluído da conta', async () => {
      prisma.user.findMany.mockResolvedValue([]);

      await service.buscar('user-1', 'gabi');

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: {
          id: { not: 'user-1' },
          fullName: { not: 'Usuário removido' },
          OR: [{ fullName: { contains: 'gabi', mode: 'insensitive' } }, { nickname: { contains: 'gabi', mode: 'insensitive' } }],
        },
        take: 20,
      });
    });

    it('marca jaSegue:true pra quem já é seguido pelo usuário que buscou', async () => {
      prisma.user.findMany.mockResolvedValue([
        { id: 'user-2', fullName: 'Gabriel Souza', nickname: 'Gabi', avatarUrl: null },
        { id: 'user-3', fullName: 'Gabriela Lima', nickname: null, avatarUrl: null },
      ]);
      prisma.playerFollow.findMany.mockResolvedValue([{ followingId: 'user-2' }]);

      const resultado = await service.buscar('user-1', 'gabi');

      expect(resultado).toEqual([
        { id: 'user-2', fullName: 'Gabriel Souza', nickname: 'Gabi', avatarUrl: null, jaSegue: true },
        { id: 'user-3', fullName: 'Gabriela Lima', nickname: null, avatarUrl: null, jaSegue: false },
      ]);
    });

    it('nenhum resultado: não chama playerFollow.findMany à toa', async () => {
      prisma.user.findMany.mockResolvedValue([]);

      const resultado = await service.buscar('user-1', 'ninguemcomessenome');

      expect(resultado).toEqual([]);
      expect(prisma.playerFollow.findMany).not.toHaveBeenCalled();
    });
  });
});

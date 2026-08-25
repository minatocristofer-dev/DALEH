import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { TeamAuthorizationService } from './team-authorization.service';

describe('TeamAuthorizationService.exigirCapitaoOuDono', () => {
  const teamId = 'team-1';
  const donoId = 'user-dono';
  const capitaoId = 'user-capitao';
  const membroComumId = 'user-membro-comum';
  const usuarioDeOutroTimeId = 'user-outro-time';

  let prisma: {
    team: { findUnique: jest.Mock };
    teamMember: { findUnique: jest.Mock; findMany: jest.Mock };
  };
  let service: TeamAuthorizationService;

  beforeEach(() => {
    prisma = {
      team: { findUnique: jest.fn() },
      teamMember: { findUnique: jest.fn(), findMany: jest.fn() },
    };
    service = new TeamAuthorizationService(prisma as unknown as PrismaService);
  });

  it('permite quando o usuário é o dono do time', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: teamId, ownerId: donoId });

    await expect(service.exigirCapitaoOuDono(teamId, donoId)).resolves.toEqual({
      id: teamId,
      ownerId: donoId,
    });
    expect(prisma.teamMember.findUnique).not.toHaveBeenCalled();
  });

  it('permite quando o usuário é capitão ativo do time', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: teamId, ownerId: donoId });
    prisma.teamMember.findUnique.mockResolvedValue({
      teamId,
      userId: capitaoId,
      status: 'active',
      papel: 'CAPITAO',
    });

    await expect(service.exigirCapitaoOuDono(teamId, capitaoId)).resolves.toEqual({
      id: teamId,
      ownerId: donoId,
    });
  });

  it('rejeita com 403 quando o usuário é membro comum (JOGADOR) do time', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: teamId, ownerId: donoId });
    prisma.teamMember.findUnique.mockResolvedValue({
      teamId,
      userId: membroComumId,
      status: 'active',
      papel: 'JOGADOR',
    });

    await expect(service.exigirCapitaoOuDono(teamId, membroComumId)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('rejeita com 403 quando o usuário não pertence ao time', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: teamId, ownerId: donoId });
    prisma.teamMember.findUnique.mockResolvedValue(null);

    await expect(service.exigirCapitaoOuDono(teamId, usuarioDeOutroTimeId)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('lança 404 quando o time não existe', async () => {
    prisma.team.findUnique.mockResolvedValue(null);

    await expect(service.exigirCapitaoOuDono('time-inexistente', donoId)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});

describe('TeamAuthorizationService.obterGestoresDoTime', () => {
  let prisma: { team: { findUnique: jest.Mock }; teamMember: { findMany: jest.Mock } };
  let service: TeamAuthorizationService;

  beforeEach(() => {
    prisma = {
      team: { findUnique: jest.fn() },
      teamMember: { findMany: jest.fn() },
    };
    service = new TeamAuthorizationService(prisma as unknown as PrismaService);
  });

  it('devolve o dono mais capitão/vice ativos, sem duplicar', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: 'time-1', ownerId: 'user-dono' });
    prisma.teamMember.findMany.mockResolvedValue([
      { userId: 'user-capitao' },
      { userId: 'user-vice' },
    ]);

    const gestores = await service.obterGestoresDoTime('time-1');

    expect(gestores).toEqual(['user-dono', 'user-capitao', 'user-vice']);
  });

  it('não duplica quando o dono também aparece como capitão ativo', async () => {
    prisma.team.findUnique.mockResolvedValue({ id: 'time-1', ownerId: 'user-dono' });
    prisma.teamMember.findMany.mockResolvedValue([{ userId: 'user-dono' }]);

    const gestores = await service.obterGestoresDoTime('time-1');

    expect(gestores).toEqual(['user-dono']);
  });

  it('lança 404 quando o time não existe', async () => {
    prisma.team.findUnique.mockResolvedValue(null);

    await expect(service.obterGestoresDoTime('time-inexistente')).rejects.toBeInstanceOf(NotFoundException);
  });
});

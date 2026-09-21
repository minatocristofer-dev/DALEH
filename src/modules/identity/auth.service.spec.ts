import { ConflictException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { SupabaseAuthService } from './supabase-auth.service';

describe('AuthService', () => {
  let prisma: any;
  let jwt: { sign: jest.Mock };
  let supabaseAuth: { verificarToken: jest.Mock };
  let service: AuthService;

  beforeEach(() => {
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn() },
      teamMember: { findMany: jest.fn() },
      matchAttendance: { count: jest.fn().mockResolvedValue(0) },
      matchEvent: { count: jest.fn().mockResolvedValue(0) },
      callUp: { count: jest.fn().mockResolvedValue(0) },
      $transaction: jest.fn(),
    };
    jwt = { sign: jest.fn().mockReturnValue('token-assinado') };
    supabaseAuth = { verificarToken: jest.fn() };
    service = new AuthService(
      prisma as unknown as PrismaService,
      jwt as unknown as JwtService,
      supabaseAuth as unknown as SupabaseAuthService,
    );
  });

  describe('register', () => {
    it('cria a conta e devolve um accessToken quando o e-mail ainda não existe', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          user: { create: jest.fn().mockResolvedValue({ id: 'user-1', email: 'novo@teste.com' }) },
          playerProfile: { create: jest.fn() },
          modalidade: { findUnique: jest.fn().mockResolvedValue(null) },
          playerModalidade: { create: jest.fn() },
          playerStats: { create: jest.fn() },
          role: { findUnique: jest.fn().mockResolvedValue(null) },
          userRole: { create: jest.fn() },
        }),
      );

      const resultado = await service.register({
        fullName: 'Novo Usuário',
        email: 'novo@teste.com',
        password: 'senha12345',
        city: 'Santa Maria',
        state: 'RS',
        modalidades: [],
      } as any);

      expect(resultado).toEqual({ accessToken: 'token-assinado' });
      expect(jwt.sign).toHaveBeenCalledWith({ sub: 'user-1', email: 'novo@teste.com' });
    });

    it('rejeita com 409 quando o e-mail já está cadastrado', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'existente', email: 'ja@existe.com' });

      await expect(
        service.register({ email: 'ja@existe.com' } as any),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    // Achado em QA real: telefone repetido derrubava o cadastro com um 500
    // cru do Postgres ("Unique constraint failed on the fields: (phone)"),
    // em vez de uma mensagem que fizesse sentido pra quem está se cadastrando.
    it('rejeita com 409 (não 500) quando o telefone já está cadastrado por outra conta', async () => {
      prisma.user.findUnique.mockImplementation(({ where }: any) => {
        if (where.email) return Promise.resolve(null);
        if (where.phone) return Promise.resolve({ id: 'outro-usuario', phone: '51999999999' });
        return Promise.resolve(null);
      });

      await expect(
        service.register({ email: 'novo@teste.com', phone: '51999999999' } as any),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('telefone informado mas ainda livre: cadastro segue normalmente', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.$transaction.mockImplementation(async (fn: any) =>
        fn({
          user: { create: jest.fn().mockResolvedValue({ id: 'user-1', email: 'novo@teste.com' }) },
          playerProfile: { create: jest.fn() },
          modalidade: { findUnique: jest.fn().mockResolvedValue(null) },
          playerModalidade: { create: jest.fn() },
          playerStats: { create: jest.fn() },
          role: { findUnique: jest.fn().mockResolvedValue(null) },
          userRole: { create: jest.fn() },
        }),
      );

      const resultado = await service.register({
        fullName: 'Novo Usuário',
        email: 'novo@teste.com',
        phone: '51988887777',
        password: 'senha12345',
        modalidades: [],
      } as any);

      expect(resultado).toEqual({ accessToken: 'token-assinado' });
    });
  });

  describe('login', () => {
    it('devolve accessToken quando a senha confere', async () => {
      const passwordHash = await bcrypt.hash('senha-correta', 4);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'a@teste.com', passwordHash });

      const resultado = await service.login({ email: 'a@teste.com', password: 'senha-correta' } as any);

      expect(resultado).toEqual({ accessToken: 'token-assinado' });
    });

    it('rejeita com 401 quando a senha está errada', async () => {
      const passwordHash = await bcrypt.hash('senha-correta', 4);
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'a@teste.com', passwordHash });

      await expect(
        service.login({ email: 'a@teste.com', password: 'senha-errada' } as any),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejeita com 401 quando o e-mail não existe', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nao-existe@teste.com', password: 'qualquer' } as any),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('me', () => {
    it('Fase 9 — calcula a idade a partir de birthDate (já fez aniversário este ano)', async () => {
      const hoje = new Date();
      const nascimento = new Date(Date.UTC(hoje.getUTCFullYear() - 33, 0, 1)); // 1º de janeiro, já passou
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        email: 'jogador@teste.com',
        avatarUrl: null,
        city: null,
        state: null,
        birthDate: nascimento,
        playerProfile: null,
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      const perfil = await service.me('user-1');

      expect(perfil.idade).toBe(33);
    });

    it('Fase 9 — idade considera que o aniversário deste ano ainda não chegou', async () => {
      const hoje = new Date();
      // Nascido daqui a 1 dia (no calendário, ex: amanhã) — ainda não fez
      // aniversário esse ano, então a idade tem que ser uma a menos.
      const amanha = new Date(hoje.getTime() + 24 * 60 * 60 * 1000);
      const nascimento = new Date(Date.UTC(hoje.getUTCFullYear() - 20, amanha.getUTCMonth(), amanha.getUTCDate()));
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        email: 'jogador@teste.com',
        avatarUrl: null,
        city: null,
        state: null,
        birthDate: nascimento,
        playerProfile: null,
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      const perfil = await service.me('user-1');

      expect(perfil.idade).toBe(19);
    });

    it('Fase 9 — idade é nula quando não existe data de nascimento (caso hoje, pra praticamente todo mundo)', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        email: 'jogador@teste.com',
        avatarUrl: null,
        city: null,
        state: null,
        birthDate: null,
        playerProfile: null,
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      const perfil = await service.me('user-1');

      expect(perfil.idade).toBeNull();
    });

    it('devolve dados reais do usuário + estatísticas calculadas a partir de eventos existentes', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        email: 'jogador@teste.com',
        avatarUrl: null,
        city: 'Santa Maria',
        state: 'RS',
        playerProfile: { dominantFoot: 'Direito', bio: null },
        playerModalidades: [
          { posicaoPrincipal: 'Ala', posicaoSecundaria: null, modalidade: { key: 'FUTSAL', label: 'Futsal' } },
        ],
      });
      prisma.teamMember.findMany.mockResolvedValue([
        { papel: 'CAPITAO', status: 'active', team: { id: 'time-1', name: 'DALEH FC', crestUrl: null } },
        { papel: 'JOGADOR', status: 'removed', team: { id: 'time-2', name: 'Ex-Time', crestUrl: null } },
      ]);
      prisma.matchAttendance.count.mockResolvedValue(5);
      prisma.matchEvent.count
        .mockResolvedValueOnce(3) // goal
        .mockResolvedValueOnce(2) // assist
        .mockResolvedValueOnce(1) // yellow
        .mockResolvedValueOnce(0) // red
        .mockResolvedValueOnce(1); // mvp
      prisma.callUp.count.mockResolvedValue(4);

      const perfil = await service.me('user-1');

      expect(perfil.fullName).toBe('Jogador Teste');
      expect(perfil.email).toBe('jogador@teste.com');
      expect(perfil.dominantFoot).toBe('Direito');
      expect(perfil.modalidades).toEqual([
        { modalidade: 'FUTSAL', label: 'Futsal', posicaoPrincipal: 'Ala', posicaoSecundaria: null },
      ]);
      expect(perfil.estatisticas).toEqual({
        jogosDisputados: 5,
        gols: 3,
        assistencias: 2,
        cartoesAmarelos: 1,
        cartoesVermelhos: 0,
        mvp: 1,
        convocacoes: 4,
      });
      expect(perfil.timesAtuais).toEqual([{ id: 'time-1', name: 'DALEH FC', crestUrl: null, papel: 'CAPITAO' }]);
      expect(perfil.timesAnteriores).toEqual([{ id: 'time-2', name: 'Ex-Time', crestUrl: null }]);
    });

    it('conta "jogos disputados" excluindo partida cancelada e partida futura (Fase 7 — risco 1)', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        email: 'jogador@teste.com',
        avatarUrl: null,
        city: null,
        state: null,
        playerProfile: null,
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.me('user-1');

      expect(prisma.matchAttendance.count).toHaveBeenCalledWith({
        where: {
          userId: 'user-1',
          status: 'confirmed',
          match: { status: { not: 'cancelled' }, scheduledAt: { lte: expect.any(Date) } },
        },
      });
    });

    it('não inventa estatística nenhuma quando o jogador nunca jogou — tudo sai zerado', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-novo',
        fullName: 'Novato',
        email: 'novato@teste.com',
        avatarUrl: null,
        city: null,
        state: null,
        playerProfile: null,
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      const perfil = await service.me('user-novo');

      expect(perfil.dominantFoot).toBeNull();
      expect(perfil.bio).toBeNull();
      expect(perfil.modalidades).toEqual([]);
      expect(perfil.estatisticas).toEqual({
        jogosDisputados: 0,
        gols: 0,
        assistencias: 0,
        cartoesAmarelos: 0,
        cartoesVermelhos: 0,
        mvp: 0,
        convocacoes: 0,
      });
      expect(perfil.timesAtuais).toEqual([]);
      expect(perfil.timesAnteriores).toEqual([]);
    });

    it('lança 404 quando o usuário do token não existe mais', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.me('user-removido')).rejects.toBeInstanceOf(NotFoundException);
    });
  });

  describe('perfilPublico', () => {
    it('devolve o mesmo formato de me(), mas sem o e-mail', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-2',
        fullName: 'Outro Jogador',
        email: 'outro@teste.com',
        avatarUrl: null,
        city: 'Porto Alegre',
        state: 'RS',
        playerProfile: { dominantFoot: 'Esquerdo', bio: 'Gosto de jogar de ala.' },
        playerModalidades: [
          { posicaoPrincipal: 'Pivô', posicaoSecundaria: null, modalidade: { key: 'FUTSAL', label: 'Futsal' } },
        ],
      });
      prisma.teamMember.findMany.mockResolvedValue([
        { papel: 'JOGADOR', status: 'active', team: { id: 'time-3', name: 'Amigos do Zé', crestUrl: null } },
      ]);
      prisma.matchAttendance.count.mockResolvedValue(7);
      prisma.matchEvent.count
        .mockResolvedValueOnce(1)
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(0);
      prisma.callUp.count.mockResolvedValue(2);

      const perfil = await service.perfilPublico('user-2');

      expect(perfil).not.toHaveProperty('email');
      expect(perfil.fullName).toBe('Outro Jogador');
      expect(perfil.city).toBe('Porto Alegre');
      expect(perfil.dominantFoot).toBe('Esquerdo');
      expect(perfil.bio).toBe('Gosto de jogar de ala.');
      expect(perfil.modalidades).toEqual([
        { modalidade: 'FUTSAL', label: 'Futsal', posicaoPrincipal: 'Pivô', posicaoSecundaria: null },
      ]);
      expect(perfil.estatisticas.jogosDisputados).toBe(7);
      expect(perfil.timesAtuais).toEqual([{ id: 'time-3', name: 'Amigos do Zé', crestUrl: null, papel: 'JOGADOR' }]);
    });

    it('lança 404 quando o jogador consultado não existe', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.perfilPublico('user-inexistente')).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});

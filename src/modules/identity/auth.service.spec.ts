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
      user: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
      teamMember: { findMany: jest.fn() },
      matchAttendance: { count: jest.fn().mockResolvedValue(0) },
      matchEvent: { count: jest.fn().mockResolvedValue(0) },
      callUp: { count: jest.fn().mockResolvedValue(0) },
      deviceToken: { deleteMany: jest.fn() },
      notification: { deleteMany: jest.fn() },
      playerProfile: { deleteMany: jest.fn(), upsert: jest.fn() },
      modalidade: { findUnique: jest.fn() },
      playerModalidade: { findUnique: jest.fn(), update: jest.fn() },
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

    it('timesAtuais inclui número da camisa e data de entrada quando o TeamMember já tem esses dados', async () => {
      const dataDeEntrada = new Date('2026-03-15T00:00:00.000Z');
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
      prisma.teamMember.findMany.mockResolvedValue([
        {
          papel: 'CAPITAO',
          status: 'active',
          numeroCamisa: 10,
          criadoEm: dataDeEntrada,
          team: { id: 'time-1', name: 'DALEH FC', crestUrl: null },
        },
      ]);

      const perfil = await service.me('user-1');

      expect(perfil.timesAtuais[0]).toMatchObject({ numeroCamisa: 10, desde: dataDeEntrada });
    });

    it('timesAtuais devolve desde=null pra quem já estava no elenco antes desta fase (nunca inventa a data)', async () => {
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
      prisma.teamMember.findMany.mockResolvedValue([
        { papel: 'JOGADOR', status: 'active', numeroCamisa: null, criadoEm: null, team: { id: 'time-1', name: 'DALEH FC', crestUrl: null } },
      ]);

      const perfil = await service.me('user-1');

      expect(perfil.timesAtuais[0]).toMatchObject({ numeroCamisa: null, desde: null });
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

  describe('excluirPropriaConta', () => {
    it('anonimiza os dados pessoais em vez de apagar a linha do usuário (preserva histórico compartilhado)', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'jogador@teste.com' });
      prisma.$transaction.mockImplementation(async (promises: any[]) => Promise.all(promises));

      await service.excluirPropriaConta('user-1');

      expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
      expect(prisma.notification.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
      expect(prisma.playerProfile.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1' } });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: expect.objectContaining({
          email: null,
          phone: null,
          passwordHash: null,
          fullName: 'Usuário removido',
          avatarUrl: null,
        }),
      });
      // Nunca um DELETE físico do usuário — é isso que preserva MatchEvent,
      // CallUp, TeamCharge etc. de outras pessoas sem violar FK.
      expect(prisma.user.delete).toBeUndefined();
    });

    it('lança 404 ao tentar excluir uma conta que não existe (nunca derruba em silêncio)', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(service.excluirPropriaConta('user-inexistente')).rejects.toBeInstanceOf(NotFoundException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });
  });

  describe('atualizarPerfil (apelido)', () => {
    it('salva o apelido com espaços nas pontas removidos', async () => {
      prisma.user.update.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        fullName: 'Jogador Teste',
        nickname: 'Jota',
        playerModalidades: [],
      });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.atualizarPerfil('user-1', { nickname: '  Jota  ' });

      expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'user-1' }, data: { nickname: 'Jota' } });
    });

    it('apelido vazio/só espaço vira null em vez de salvar string vazia', async () => {
      prisma.user.update.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', fullName: 'Jogador Teste', nickname: null, playerModalidades: [] });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.atualizarPerfil('user-1', { nickname: '   ' });

      expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'user-1' }, data: { nickname: null } });
    });

    it('apelido null explícito (apagar) continua funcionando mesmo com a guarda nova de "campo ausente"', async () => {
      prisma.user.update.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', fullName: 'Jogador Teste', nickname: null, playerModalidades: [] });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.atualizarPerfil('user-1', { nickname: null });

      expect(prisma.user.update).toHaveBeenCalledWith({ where: { id: 'user-1' }, data: { nickname: null } });
    });

    it('PATCH só com dominantFoot não mexe no apelido (bug encontrado ao implementar: nickname?.trim() || null apagava o apelido existente sempre que vinha ausente do corpo)', async () => {
      prisma.playerProfile.upsert.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', fullName: 'Jogador Teste', nickname: 'Jota', playerModalidades: [] });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.atualizarPerfil('user-1', { dominantFoot: 'Esquerdo' });

      expect(prisma.user.update).not.toHaveBeenCalled();
      expect(prisma.playerProfile.upsert).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        create: { userId: 'user-1', dominantFoot: 'Esquerdo' },
        update: { dominantFoot: 'Esquerdo' },
      });
    });
  });

  describe('atualizarPosicao', () => {
    it('atualiza a posição de uma modalidade em que o jogador já está cadastrado', async () => {
      prisma.modalidade.findUnique.mockResolvedValue({ id: 'mod-1', key: 'FUTSAL' });
      prisma.playerModalidade.findUnique.mockResolvedValue({ id: 'pm-1', userId: 'user-1', modalidadeId: 'mod-1' });
      prisma.playerModalidade.update.mockResolvedValue({});
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', fullName: 'Jogador Teste', nickname: null, playerModalidades: [] });
      prisma.teamMember.findMany.mockResolvedValue([]);

      await service.atualizarPosicao('user-1', { modalidade: 'FUTSAL' as any, posicaoPrincipal: 'Pivô', posicaoSecundaria: 'Ala' });

      expect(prisma.playerModalidade.update).toHaveBeenCalledWith({
        where: { id: 'pm-1' },
        data: { posicaoPrincipal: 'Pivô', posicaoSecundaria: 'Ala' },
      });
    });

    it('jogador tentando editar posição numa modalidade em que nunca se cadastrou recebe 404, não cria vínculo novo', async () => {
      prisma.modalidade.findUnique.mockResolvedValue({ id: 'mod-2', key: 'CAMPO11' });
      prisma.playerModalidade.findUnique.mockResolvedValue(null);

      await expect(
        service.atualizarPosicao('user-1', { modalidade: 'CAMPO11' as any, posicaoPrincipal: 'Atacante' }),
      ).rejects.toThrow(NotFoundException);
      expect(prisma.playerModalidade.update).not.toHaveBeenCalled();
    });
  });
});

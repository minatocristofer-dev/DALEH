import { BadRequestException, ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { AuthProvider } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SocialLoginDto } from './dto/social-login.dto';
import { SupabaseAuthService } from './supabase-auth.service';

const SALT_ROUNDS = 10;

// Mapeia o nome do provider que o Supabase Auth devolve pro enum do nosso schema.
// Apple já mapeado mesmo sem estar habilitado ainda — ligar o provider no
// Supabase no futuro não vai exigir nenhuma mudança aqui.
const SUPABASE_PROVIDER_MAP: Record<string, AuthProvider> = {
  google: 'GOOGLE',
  apple: 'APPLE',
};

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private supabaseAuth: SupabaseAuthService,
  ) {}

  async register(dto: RegisterDto) {
    const existente = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existente) {
      throw new ConflictException('Já existe uma conta com este e-mail.');
    }

    // `phone` também é único no banco (ver schema) — sem essa checagem aqui,
    // a violação só aparecia lá na frente como um erro genérico de banco
    // (500 "Internal server error"), sem nenhuma mensagem que fizesse
    // sentido pra quem está se cadastrando.
    if (dto.phone) {
      const telefoneJaCadastrado = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
      if (telefoneJaCadastrado) {
        throw new ConflictException('Já existe uma conta com este telefone.');
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);

    // Cria o usuário, o perfil e todas as modalidades numa única transação —
    // ou tudo é criado, ou nada é (evita usuário "pela metade" se algo falhar no meio).
    const user = await this.prisma.$transaction(async (tx) => {
      const novoUsuario = await tx.user.create({
        data: {
          fullName: dto.fullName,
          email: dto.email,
          passwordHash,
          phone: dto.phone,
          city: dto.city,
          state: dto.state,
          authProvider: 'EMAIL',
        },
      });

      await tx.playerProfile.create({
        data: {
          userId: novoUsuario.id,
          dominantFoot: dto.dominantFoot,
        },
      });

      for (const m of dto.modalidades) {
        const modalidade = await tx.modalidade.findUnique({ where: { key: m.modalidade } });
        if (!modalidade) continue; // modalidade inexistente é ignorada silenciosamente (validação de enum já cobre o principal)

        await tx.playerModalidade.create({
          data: {
            userId: novoUsuario.id,
            modalidadeId: modalidade.id,
            posicaoPrincipal: m.posicaoPrincipal,
            posicaoSecundaria: m.posicaoSecundaria,
          },
        });

        // Estatísticas nascem zeradas — ver seção 3 do plano de implementação:
        // nada de número inventado, o placar só sobe com partidas reais.
        await tx.playerStats.create({
          data: { userId: novoUsuario.id, modalidadeId: modalidade.id },
        });
      }

      const papelJogador = await tx.role.findUnique({ where: { key: 'player' } });
      if (papelJogador) {
        await tx.userRole.create({
          data: { userId: novoUsuario.id, roleId: papelJogador.id },
        });
      }

      return novoUsuario;
    });

    return this.gerarSessao(user.id, user.email!);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('E-mail ou senha inválidos.');
    }

    const senhaValida = await bcrypt.compare(dto.password, user.passwordHash);
    if (!senhaValida) {
      throw new UnauthorizedException('E-mail ou senha inválidos.');
    }

    return this.gerarSessao(user.id, user.email!);
  }

  async socialLogin(dto: SocialLoginDto) {
    const supabaseUser = await this.supabaseAuth.verificarToken(dto.accessToken);
    if (!supabaseUser.email) {
      throw new UnauthorizedException('Conta social sem e-mail associado.');
    }

    let user = await this.prisma.user.findUnique({ where: { email: supabaseUser.email } });

    if (!user) {
      if (dto.consentimentoDadosSensiveis !== true) {
        throw new BadRequestException(
          'É necessário aceitar o consentimento de dados sensíveis para concluir o cadastro.',
        );
      }

      const providerKey = supabaseUser.app_metadata?.provider as string | undefined;
      const authProvider = (providerKey && SUPABASE_PROVIDER_MAP[providerKey]) || 'EMAIL';

      user = await this.prisma.$transaction(async (tx) => {
        const novoUsuario = await tx.user.create({
          data: {
            email: supabaseUser.email,
            fullName:
              supabaseUser.user_metadata?.full_name ?? supabaseUser.user_metadata?.name ?? supabaseUser.email!,
            avatarUrl: supabaseUser.user_metadata?.avatar_url ?? null,
            authProvider,
          },
        });

        const papelJogador = await tx.role.findUnique({ where: { key: 'player' } });
        if (papelJogador) {
          await tx.userRole.create({
            data: { userId: novoUsuario.id, roleId: papelJogador.id },
          });
        }

        return novoUsuario;
      });
    }

    return this.gerarSessao(user.id, user.email!);
  }

  private gerarSessao(userId: string, email: string) {
    const accessToken = this.jwt.sign({ sub: userId, email });
    return { accessToken };
  }

  // Monta o perfil completo (com e-mail) de qualquer userId — usado tanto
  // por `me()` (próprio usuário, a partir do JWT) quanto por
  // `perfilPublico()` (Fase 7, que remove o e-mail antes de devolver).
  // Estatísticas são sempre calculadas na hora a partir de dados reais
  // (MatchAttendance, MatchEvent, CallUp) — nada é lido de `PlayerStats`,
  // porque essa tabela nasce zerada no cadastro e nunca é atualizada por
  // nenhuma partida (ver Fase 6, auditoria). Vitórias/empates/derrotas não
  // entram aqui porque `Match` não guarda placar — não dá pra calcular isso
  // com os dados atuais.
  // Idade (Fase 9) — sempre calculada a partir de `User.birthDate`, nunca
  // armazenada como número fixo (assim ela "atualiza sozinha" no aniversário
  // do jogador). `birthDate` já existia no schema desde o início, mas
  // nenhum fluxo de cadastro/edição de perfil o preenche ainda — por isso
  // continua nulo pra praticamente todo mundo hoje; isso não foi inventado
  // nem corrigido nesta fase (fora do escopo — ver relatório).
  private calcularIdade(birthDate: Date | null): number | null {
    if (!birthDate) return null;
    const hoje = new Date();
    let idade = hoje.getUTCFullYear() - birthDate.getUTCFullYear();
    const aindaNaoFezAniversarioEsteAno =
      hoje.getUTCMonth() < birthDate.getUTCMonth() ||
      (hoje.getUTCMonth() === birthDate.getUTCMonth() && hoje.getUTCDate() < birthDate.getUTCDate());
    if (aindaNaoFezAniversarioEsteAno) idade--;
    return idade;
  }

  private async montarPerfil(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        playerProfile: true,
        playerModalidades: { include: { modalidade: true } },
      },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado.');

    const memberships = await this.prisma.teamMember.findMany({
      where: { userId },
      include: { team: true },
    });

    const [jogosDisputados, gols, assistencias, cartoesAmarelos, cartoesVermelhos, mvp, convocacoes] =
      await Promise.all([
        // "Jogos disputados" só conta partida que já aconteceu de fato:
        // exclui cancelada e exclui data futura (ver Fase 7, Parte 6 —
        // Match não tem nenhum status "auto-atualizado", então exigir
        // status 'finished' subcontaria partidas reais que o criador nunca
        // marcou manualmente; futura + não-cancelada é o critério pedido).
        this.prisma.matchAttendance.count({
          where: {
            userId,
            status: 'confirmed',
            match: { status: { not: 'cancelled' }, scheduledAt: { lte: new Date() } },
          },
        }),
        this.prisma.matchEvent.count({ where: { userId, eventType: 'goal' } }),
        this.prisma.matchEvent.count({ where: { userId, eventType: 'assist' } }),
        this.prisma.matchEvent.count({ where: { userId, eventType: 'yellow' } }),
        this.prisma.matchEvent.count({ where: { userId, eventType: 'red' } }),
        this.prisma.matchEvent.count({ where: { userId, eventType: 'mvp' } }),
        this.prisma.callUp.count({ where: { userId } }),
      ]);

    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      avatarUrl: user.avatarUrl,
      city: user.city,
      state: user.state,
      dominantFoot: user.playerProfile?.dominantFoot ?? null,
      bio: user.playerProfile?.bio ?? null,
      idade: this.calcularIdade(user.birthDate),
      modalidades: user.playerModalidades.map((pm) => ({
        modalidade: pm.modalidade.key,
        label: pm.modalidade.label,
        posicaoPrincipal: pm.posicaoPrincipal,
        posicaoSecundaria: pm.posicaoSecundaria,
      })),
      estatisticas: { jogosDisputados, gols, assistencias, cartoesAmarelos, cartoesVermelhos, mvp, convocacoes },
      timesAtuais: memberships
        .filter((m) => m.status === 'active')
        .map((m) => ({ id: m.team.id, name: m.team.name, crestUrl: m.team.crestUrl, papel: m.papel })),
      timesAnteriores: memberships
        .filter((m) => m.status === 'removed')
        .map((m) => ({ id: m.team.id, name: m.team.name, crestUrl: m.team.crestUrl })),
    };
  }

  // Dados do próprio usuário logado — o JWT só carrega {sub, email} (ver
  // JwtStrategy.validate), então esse é o único jeito do app conhecer
  // nome/avatar/posição/estatísticas de quem está logado.
  async me(userId: string) {
    return this.montarPerfil(userId);
  }

  // Só troca o avatarUrl — nunca inventa/apaga nenhum outro campo do
  // perfil. A URL já vem pronta de quem fez o upload (SupabaseStorageService).
  async atualizarAvatar(userId: string, avatarUrl: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { avatarUrl } });
    return this.montarPerfil(userId);
  }

  // Perfil público (Fase 7) — qualquer usuário autenticado pode ver o de
  // qualquer outro (sem exigir time/jogo em comum, por decisão explícita do
  // prompt desta fase). Mesmo formato de `me()`, só sem o e-mail.
  async perfilPublico(userId: string) {
    const { email: _email, ...perfilPublico } = await this.montarPerfil(userId);
    return perfilPublico;
  }
}

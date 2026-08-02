import { BadRequestException, ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
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
}

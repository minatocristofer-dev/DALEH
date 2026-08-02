import { Injectable, UnauthorizedException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseAuthService {
  private readonly client: SupabaseClient;

  constructor() {
    this.client = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);
  }

  // Verifica o access token emitido pelo Supabase Auth direto com o servidor
  // deles — evita ter que gerenciar JWKS/segredo de assinatura por conta própria.
  async verificarToken(accessToken: string) {
    const { data, error } = await this.client.auth.getUser(accessToken);
    if (error || !data.user) {
      throw new UnauthorizedException('Token de login social inválido ou expirado.');
    }
    return data.user;
  }
}

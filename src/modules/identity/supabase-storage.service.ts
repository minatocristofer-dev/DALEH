import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const BUCKET = 'avatars';

// Serviço separado do SupabaseAuthService (que usa a chave anon, só pra
// verificar token de login social) — este usa a service role key, porque
// escrever no Storage em nome do usuário precisa de permissão elevada
// (nosso backend nunca repassa a sessão do Supabase, só o nosso próprio
// JWT — quem garante "é este usuário mesmo" é o AuthGuard('jwt') do
// endpoint, não o Supabase).
@Injectable()
export class SupabaseStorageService {
  // Criado sob demanda, não no construtor — se SUPABASE_SERVICE_ROLE_KEY
  // ainda não estiver configurada (ex: variável nova, ainda não posta no
  // Render), isso não pode derrubar o boot da aplicação inteira (mesmo
  // cuidado documentado no projeto pra outras integrações opcionais/novas).
  // Só quem tentar enviar um avatar recebe o erro, e de forma clara.
  private client: SupabaseClient | undefined;

  private obterClient(): SupabaseClient {
    if (this.client) return this.client;

    const url = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !serviceRoleKey) {
      throw new InternalServerErrorException(
        'Upload de foto ainda não está configurado no servidor (falta SUPABASE_SERVICE_ROLE_KEY).',
      );
    }
    this.client = createClient(url, serviceRoleKey);
    return this.client;
  }

  // Sobrescreve sempre no mesmo caminho (um avatar por usuário) — trocar de
  // foto substitui a anterior, nunca acumula lixo no bucket.
  async enviarAvatar(userId: string, arquivo: Buffer, contentType: string): Promise<string> {
    const client = this.obterClient();
    const caminho = `${userId}.png`;
    const { error } = await client.storage.from(BUCKET).upload(caminho, arquivo, {
      contentType,
      upsert: true,
    });
    if (error) {
      throw new InternalServerErrorException('Não foi possível salvar a foto de perfil.');
    }

    const { data } = client.storage.from(BUCKET).getPublicUrl(caminho);
    // Cache-busting: sem isso, o app/CDN mostrariam a foto antiga depois de
    // trocar, porque o caminho do arquivo não muda (upsert no mesmo nome).
    return `${data.publicUrl}?v=${Date.now()}`;
  }
}

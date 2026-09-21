import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Serviço compartilhado (usado por avatar de jogador e escudo de time) —
// service role key, porque escrever no Storage em nome do usuário precisa
// de permissão elevada (o backend nunca repassa a sessão do Supabase, só o
// nosso próprio JWT — quem garante "pode fazer isso" é o AuthGuard('jwt') +
// a checagem de dono/capitão de cada endpoint, não o Supabase).
@Injectable()
export class SupabaseStorageService {
  // Criado sob demanda, não no construtor — se SUPABASE_SERVICE_ROLE_KEY
  // ainda não estiver configurada, isso não pode derrubar o boot da
  // aplicação inteira (mesmo cuidado documentado no projeto pra outras
  // integrações opcionais/novas). Só quem tentar enviar uma imagem recebe
  // o erro, e de forma clara.
  private client: SupabaseClient | undefined;

  private obterClient(): SupabaseClient {
    if (this.client) return this.client;

    const url = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !serviceRoleKey) {
      throw new InternalServerErrorException(
        'Upload de imagem ainda não está configurado no servidor (falta SUPABASE_SERVICE_ROLE_KEY).',
      );
    }
    this.client = createClient(url, serviceRoleKey);
    return this.client;
  }

  // Sobrescreve sempre no mesmo caminho (um arquivo por dono) — trocar a
  // imagem substitui a anterior, nunca acumula lixo no bucket.
  async enviarImagem(bucket: string, caminho: string, arquivo: Buffer, contentType: string): Promise<string> {
    const client = this.obterClient();
    const { error } = await client.storage.from(bucket).upload(caminho, arquivo, {
      contentType,
      upsert: true,
    });
    if (error) {
      throw new InternalServerErrorException('Não foi possível salvar a imagem.');
    }

    const { data } = client.storage.from(bucket).getPublicUrl(caminho);
    // Cache-busting: sem isso, o app/CDN mostrariam a imagem antiga depois
    // de trocar, porque o caminho do arquivo não muda (upsert no mesmo nome).
    return `${data.publicUrl}?v=${Date.now()}`;
  }
}

import { Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Serviço compartilhado (usado por avatar de jogador e escudo de time) —
// service role key, porque escrever no Storage em nome do usuário precisa
// de permissão elevada (o backend nunca repassa a sessão do Supabase, só o
// nosso próprio JWT — quem garante "pode fazer isso" é o AuthGuard('jwt') +
// a checagem de dono/capitão de cada endpoint, não o Supabase).
@Injectable()
export class SupabaseStorageService {
  private readonly logger = new Logger(SupabaseStorageService.name);

  // Criado sob demanda, não no construtor — se SUPABASE_SERVICE_ROLE_KEY
  // ainda não estiver configurada, isso não pode derrubar o boot da
  // aplicação inteira (mesmo cuidado documentado no projeto pra outras
  // integrações opcionais/novas). Só quem tentar enviar uma imagem recebe
  // o erro, e de forma clara.
  private client: SupabaseClient | undefined;
  // Buckets já confirmados nesta instância do processo — evita checar a
  // existência do bucket (uma chamada extra à API) em todo upload.
  private readonly bucketsVerificados = new Set<string>();

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

  // Nenhum dos buckets usados hoje (`avatars`, `crests`) é criado por
  // migration/seed — só existiam se alguém os criou manualmente no painel
  // do Supabase. Em vez de depender disso silenciosamente, garante aqui: se
  // o bucket não existir, cria como público (precisa ser público pra
  // `getPublicUrl` funcionar, já que o app nunca autentica direto no
  // Supabase pra baixar a foto).
  private async garantirBucket(client: SupabaseClient, bucket: string): Promise<void> {
    if (this.bucketsVerificados.has(bucket)) return;

    const { data: existente, error: erroConsulta } = await client.storage.getBucket(bucket);
    if (existente) {
      this.bucketsVerificados.add(bucket);
      return;
    }

    const { error: erroCriacao } = await client.storage.createBucket(bucket, { public: true });
    if (erroCriacao) {
      this.logger.error(
        `Bucket "${bucket}" não existe e não foi possível criá-lo automaticamente: ${erroCriacao.message} ` +
          `(consulta original: ${erroConsulta?.message ?? 'bucket não encontrado'})`,
        erroCriacao,
      );
      throw new InternalServerErrorException('Não foi possível salvar a imagem.');
    }
    this.bucketsVerificados.add(bucket);
  }

  // Sobrescreve sempre no mesmo caminho (um arquivo por dono) — trocar a
  // imagem substitui a anterior, nunca acumula lixo no bucket.
  async enviarImagem(bucket: string, caminho: string, arquivo: Buffer, contentType: string): Promise<string> {
    const client = this.obterClient();
    await this.garantirBucket(client, bucket);
    const { error } = await client.storage.from(bucket).upload(caminho, arquivo, {
      contentType,
      upsert: true,
    });
    if (error) {
      // O erro genérico pro cliente nunca muda (não expor detalhe interno
      // de infra pro app) — mas sem logar a causa real aqui, esse tipo de
      // falha (bucket errado, política de acesso, projeto pausado, etc.)
      // fica impossível de diagnosticar a distância.
      this.logger.error(`Falha ao enviar imagem pro bucket "${bucket}" (${caminho}): ${error.message}`, error);
      throw new InternalServerErrorException('Não foi possível salvar a imagem.');
    }

    const { data } = client.storage.from(bucket).getPublicUrl(caminho);
    // Cache-busting: sem isso, o app/CDN mostrariam a imagem antiga depois
    // de trocar, porque o caminho do arquivo não muda (upsert no mesmo nome).
    return `${data.publicUrl}?v=${Date.now()}`;
  }
}

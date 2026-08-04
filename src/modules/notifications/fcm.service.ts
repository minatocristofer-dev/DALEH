import { Injectable, Logger } from '@nestjs/common';

// Push de verdade (Firebase Cloud Messaging) — só é ativado se as env vars
// FIREBASE_* estiverem configuradas. O SDK do firebase-admin só é carregado
// (require) quando as credenciais existem: importá-lo sempre, mesmo sem uso,
// já estourou o limite de memória do plano free do Render (o SDK arrasta
// gRPC/protobuf, é pesado só de carregar). Sem credenciais, vira no-op com
// log, pra não travar o resto do app enquanto a conta do Firebase não é
// criada (ver CLAUDE.md, seção de infraestrutura).
@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private app: any = null;

  constructor() {
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      this.app = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      this.logger.warn('Firebase não configurado (FIREBASE_*) — push real desativado, só notificação in-app.');
    }
  }

  get ativo() {
    return this.app !== null;
  }

  // Nunca lança erro — push é best-effort, não pode derrubar a operação
  // principal (ex: convocar o elenco) só porque um token expirou.
  async enviarParaTokens(tokens: string[], titulo: string, corpo: string, data?: Record<string, string>) {
    if (!this.app || tokens.length === 0) return;
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const admin = require('firebase-admin');
      await admin.messaging(this.app).sendEachForMulticast({
        tokens,
        notification: { title: titulo, body: corpo },
        data,
      });
    } catch (err) {
      this.logger.error(`Falha ao enviar push: ${(err as Error).message}`);
    }
  }
}

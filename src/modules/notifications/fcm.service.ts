import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

// Push de verdade (Firebase Cloud Messaging) — só é ativado se as env vars
// FIREBASE_* estiverem configuradas. Sem elas, vira no-op com log, pra não
// travar o resto do app enquanto a conta do Firebase não é criada (ver
// CLAUDE.md, seção de infraestrutura).
@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private app: admin.app.App | null = null;

  constructor() {
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
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

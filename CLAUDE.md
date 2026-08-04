# DALEH — Contexto completo do projeto

> Este arquivo dá a qualquer instância do Claude o contexto completo do
> projeto sem precisar reconstruir o histórico da conversa. Fica na raiz do
> repositório `daleh-api` (lido automaticamente pelo Claude Code).

---

## 1. O que é o DALEH

DALEH (anteriormente chamado de "FullMatch" durante o planejamento) é um app que
pretende ser **a maior plataforma de futebol amador do Brasil**. Não é só um app de
organizar pelada — é um ecossistema que conecta jogadores, times, quadras,
organizadores de campeonato, árbitros e patrocinadores, com o objetivo de eliminar
a dependência do WhatsApp pra esse tipo de organização.

**Princípio central do produto**: o ativo mais defensável não são as features de
organização (isso o WhatsApp meio que já resolve) — é o **histórico esportivo
permanente** do jogador (estatísticas, conquistas, carteirinha digital). A analogia
usada durante o planejamento: "o Strava do futebol amador".

**Modelo mental de referência**: LinkedIn (identidade + histórico) + OpenTable
(reserva) + Uber (matching geolocalizado) + Strava (gamificação de performance),
verticalizado pra futebol de várzea.

Documentos completos de arquitetura de produto e plano de implementação estão
em `C:\Users\minat\Downloads\FullMatch_Arquitetura_Produto.md` e
`FullMatch_Plano_de_Implementacao.md`.

---

## 2. Decisões estratégicas já tomadas (e o porquê)

1. **Sequenciamento de lançamento**: não lançar os 5 tipos de usuário (jogador,
   time, quadra, organizador, admin) juntos. Densidade local antes de amplitude
   de features — dominar uma cidade antes de expandir. MVP real prioriza o
   triângulo Jogador → Time → Quadra.
2. **Monolito modular antes de microsserviços**: o backend é um monolito NestJS
   com módulos isolados por bounded context. Só extrair um módulo pra serviço
   separado quando houver dado real de gargalo.
3. **RBAC sempre com contexto, nunca papel fixo**: um usuário pode ter múltiplos
   papéis (ex: `team_admin` do time X, `venue_owner` da quadra Y). Implementado
   como `user_roles` com `context_type` + `context_id`, nunca um campo `role`
   fixo no usuário.
4. **Comissão zero nos primeiros meses por cidade lançada** (quadras).
5. **Separação futura entre "visualizar quadra" e "gerenciar quadra"** — decisão
   já tomada, desenho das telas de gestão ainda **não foi feito**.

---

## 3. Stack técnica

| Camada | Escolha | Status |
|---|---|---|
| Backend | NestJS (TypeScript) | Identity, Teams, Venues, Matches, Notifications — todos no ar |
| ORM / Banco | Prisma + PostgreSQL | Schema completo, todas as migrations aplicadas |
| Banco hospedado em | **Supabase** (projeto `glgdiymnhmcvzhtmbqqb`) — usar sempre o **pooler** (`aws-1-us-west-2.pooler.supabase.com`): porta 6543 c/ `pgbouncer=true` no `DATABASE_URL`, porta 5432 (session mode) no `DIRECT_URL`. **Nunca** usar o host direto `db.*.supabase.co` — só responde em IPv6, quebra em hosts sem rota IPv6 (ex: Render) | ✅ No ar |
| Host do servidor | **Render** (Web Service free, 512MB RAM, deploy automático do GitHub) — `https://daleh-fx5c.onrender.com/v1` | ✅ No ar |
| Auth | JWT próprio (email/senha) + login social Google via Supabase Auth (`POST /auth/social`) | Google pronto; Apple mapeado no código mas não habilitado (exige conta paga Apple Developer) |
| Push notifications | Firebase Cloud Messaging | Infra pronta no código (`NotificationsModule`), **desativada** até existir uma conta Firebase — ver seção 6.2 |
| Frontend definitivo | **Flutter** (decisão tomada, ainda não iniciado) | Não iniciado |
| Demo web temporário | React + Vite + Tailwind, pasta `daleh-web/` neste mesmo repo — `https://daleh-web.onrender.com` | Ver seção 6.1 — **não é o frontend de produção**, é só pra testar/mostrar o que já funciona |
| Protótipo de UX/visual original | React + Tailwind (artifact do Claude, arquivo `fullmatch-core.jsx` em Downloads) | Referência de design pro Flutter — ver seção 6 |

Repositório: `github.com/minatocristofer-dev/DALEH`.

**Cuidado com memória no Render free (512MB)**: já aconteceu de um `npm install`
trazer uma dependência pesada (`firebase-admin`, que arrasta gRPC/protobuf) e
estourar OOM só de ser **importada**, mesmo sem uso — o processo morria no
boot com "JavaScript heap out of memory". Corrigido usando `require()`
dentro do `if` que só roda quando as credenciais existem (`fcm.service.ts`),
em vez de `import` estático no topo do arquivo. Ao adicionar dependências
pesadas no futuro, considerar lazy-load do mesmo jeito.

---

## 4. Banco de dados — visão geral

Schema completo em `prisma/schema.prisma`, todas as migrations aplicadas
contra o banco real no Supabase (`prisma migrate deploy`), incluindo duas
adicionadas depois da migration inicial: `Match.createdById` (o schema
original não tinha como saber quem criou uma pelada avulsa) e `DeviceToken`
(token de push por dispositivo).

Tabelas por domínio:

- **Identidade/RBAC**: `users`, `player_profiles`, `modalidades`,
  `player_modalidades`, `player_stats`, `roles`, `user_roles`
- **Times**: `teams`, `team_members`, `team_finances` (schema pronto, sem
  endpoint ainda), `team_challenges`, `challenge_requests`, `call_ups`
- **Quadras**: `venues`, `venue_slots`, `bookings`
- **Jogos**: `matches` (com `created_by`), `match_attendance`, `match_events`
- **Campeonatos** (schema pronto, fase futura, sem módulo ainda):
  `championships`, `championship_teams`
- **Social/Pagamento/Notificação**: `reviews` (schema pronto, sem endpoint),
  `payments` (schema pronto, sem endpoint), `notifications`, `device_tokens`

**Modalidades**: Futsal (Goleiro, Fixo, Ala, Pivô), Society/Campo 7 (Goleiro,
Zagueiro, Lateral, Meia, Atacante), Campo 11 (Goleiro, Zagueiro, Lateral,
Volante, Meia, Atacante). Populadas via `prisma/seed.ts`.

---

## 5. Backend — o que já existe em código

Todos os módulos do roadmap original (seção 8) estão implementados e no ar.
Padrão comum a todos: DTOs com `class-validator`, todas as rotas atrás de
`@UseGuards(AuthGuard('jwt'))`, RBAC contextual (quem é dono/capitão de *qual*
recurso) checado no service — nunca só no guard genérico — via um método
privado tipo `exigirDono`/`exigirCapitaoOuDono` em cada service.

- **`src/modules/identity/`** — `POST /auth/register`, `POST /auth/login`,
  `POST /auth/social` (Google via Supabase Auth, `SupabaseAuthService`).
- **`src/modules/teams/`** — `TeamsController` (`/teams/*`: criar, listar,
  detalhe, gerenciar elenco) + `CallUpsController` (`/call-ups/*`: minhas
  convocações, responder). Convocar o elenco cria 1 `CallUp` por atleta e
  dispara `NotificationsService.notificar()` (in-app + push best-effort).
- **`src/modules/venues/`** — `VenuesController` (`/venues/*`: CRUD de
  quadra, horários recorrentes, disponibilidade por data) +
  `BookingsController` (`/bookings/*`: minhas reservas, dono
  confirma/cancela, cancelar a própria). Bloqueia reserva duplicada do mesmo
  horário/data com `409 Conflict`.
- **`src/modules/matches/`** — `MatchesController` (`/matches/*`: peladas
  avulsas — criar, confirmar/cancelar presença com lista de espera automática,
  registrar eventos de súmula) + `TeamChallengesController`
  (`/team-challenges/*`: marketplace de adversário — publicar desafio,
  solicitar, aceitar. Aceitar uma solicitação recusa as outras da mesma
  automaticamente, numa transação — regra de negócio documentada desde o
  início do projeto).
- **`src/modules/notifications/`** — `NotificationsController`
  (`/notifications/*`: inbox in-app, marcar como lida, registrar token de
  push) + `FcmService` (push real via Firebase, **atualmente em modo
  no-op** — ver seção 6.2).
- `src/common/decorators/current-user.decorator.ts` — `@CurrentUser()`,
  extrai `{id, email}` do JWT validado, usado em todo controller autenticado.
- `src/common/guards/roles.guard.ts` + `@Roles()` — RBAC de papel *global*
  (ex: `platform_admin`); RBAC de contexto é responsabilidade de cada service.
- `src/health.controller.ts` — `GET /v1/` retorna `{status: 'ok', ...}`.
- `prisma/seed.ts` — popula modalidades e papéis de RBAC.

**Ainda fora de escopo** (schema existe, sem endpoint): financeiro de time
(`team_finances`), avaliações pós-jogo (`reviews`), pagamentos (`payments`),
campeonatos (`championships`).

---

## 6. Protótipo de UX/visual (React) — referência de design pro Flutter

Existe um protótipo visual (`fullmatch-core.jsx`, em Downloads) que validou a
experiência visual e os fluxos principais, **sem conexão com API nenhuma**
(dados locais/fake). Quando o Flutter for iniciado, este é a referência de
design a seguir — não é pra redesenhar do zero.

### Design system
- Tema escuro "campo de futebol à noite": fundo verde-quase-preto
  (`--bg: #0A1512`), acento lima (`--turf: #C6FF4D`), âmbar secundário
- Tema alternativo dourado (`--turf` → `#F2C94C`) como toggle — benefício do
  plano PRO
- Tipografia bold/uppercase, cards com cantos arredondados (16px)
- Cabeçalho com padrão de listras (`fm-stripes`) simulando grama cortada

### Telas/fluxos prototipados
Cadastro (3 passos), Perfil (radar de habilidades, carteirinha digital,
animação de comemoração), Jogos (buscar adversário + peladas avulsas),
Times (elenco, convocação), Quadras (características + grade de horários),
Avisos (inbox de convocação).

### 6.1 Demo web temporário (`daleh-web/`) — **não confundir com o Flutter**

Pasta neste repo (`daleh-api/daleh-web`), Vite + React + Tailwind,
reaproveitando o visual exato do `fullmatch-core.jsx`, publicado como Static
Site separado no Render (`https://daleh-web.onrender.com`), mesma conta do
backend. Conectado de verdade em:
- Login/Cadastro (`register`/`login`/`social`)
- Times (`TeamsModule`: criar time, ver elenco, adicionar jogador por e-mail)
- Quadras (`VenuesModule`: criar quadra, listar minhas quadras)

**Ainda não conectado**: telas de Jogos/peladas, marketplace de adversário,
agenda/reserva de quadra (existe API pronta em `VenuesModule`/`MatchesModule`,
só falta a tela). Avisos/inbox de notificação também tem API pronta
(`NotificationsModule`) sem tela ainda.

**Propósito**: só validar/demonstrar o que já está funcionando ponta a ponta,
enquanto o Flutter (frontend definitivo) não começa. Não vira produto.

### 6.2 Push notifications (Firebase) — infra pronta, falta a conta

`NotificationsModule`/`FcmService` já sabem enviar push de verdade, mas ficam
em modo no-op até existirem estas env vars no Render: `FIREBASE_PROJECT_ID`,
`FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` (de uma service account do
Firebase). Passos pra ativar quando for a hora:
1. Criar projeto em console.firebase.google.com, ativar Cloud Messaging.
2. Gerar uma service account (Project Settings > Service Accounts > Generate
   new private key) — vira as 3 env vars acima.
3. Configurar essas env vars no Web Service do Render.
4. Nenhuma mudança de código é necessária — `FcmService` detecta as env vars
   sozinho no boot e ativa (ver seção 3, aviso sobre lazy-load por causa de
   memória no free tier).

---

## 7. Infraestrutura — estado atual

- **Supabase**: projeto `glgdiymnhmcvzhtmbqqb`, migration aplicada, seed
  rodado. Google habilitado no Supabase Auth (Client ID/Secret configurados
  via Management API). Apple mapeado no código, não habilitado.
- **Render**: Web Service `daleh-api` (free) rodando a API, deploy automático
  a cada push na branch `main`. Variáveis configuradas: `DATABASE_URL`,
  `DIRECT_URL`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `SUPABASE_URL`,
  `SUPABASE_ANON_KEY`. Faltam as `FIREBASE_*` (seção 6.2). Static Site
  `daleh-web` publicando o demo (seção 6.1) — os dois serviços observam o
  mesmo repo/branch, então um push dispara redeploy dos dois.
- **GitHub**: `github.com/minatocristofer-dev/DALEH`, branch `main`.
- **Domínio**: nenhum domínio próprio comprado ainda — usando os subdomínios
  gratuitos do Render (`*.onrender.com`).

**Regra de segurança**: nenhum token/senha/connection string deve ser colado
em chat/prompt em texto solto sem necessidade — sempre via `.env` local
(git-ignorado) ou variáveis de ambiente da plataforma de deploy. Tokens de
gestão (Supabase, GitHub, Render) usados durante o setup devem ser
revogados/rotacionados quando não forem mais necessários.

---

## 8. Roadmap (fases, na ordem)

```
Fundação técnica (backend + schema + migrations) ✅
        ↓
Autenticação completa (email/senha ✅, Google ✅, Apple pendente) + Perfil
        ↓
Times + Convocação ✅ (in-app pronto; push real pendente da conta Firebase)
        ↓
Quadras (agenda/reserva) ✅  →  Jogos (peladas + marketplace) ✅
        ↓
Notificações push reais (FCM) — infra pronta, falta a conta Firebase (6.2)
        ↓
Frontend definitivo em Flutter (usando fullmatch-core.jsx como referência visual)
        ↓
Google Play Console (conta paga, US$ 25 único) — não criada ainda, só quando
tiver build pronta pra testar (decisão explícita do usuário)
```

Backend dos 4 módulos principais (Identity, Teams, Venues, Matches +
Notifications) está **completo e testado** (fluxo feliz + casos negativos de
RBAC) local e em produção. O que falta pra ir pra Play Store de verdade:
Firebase real, telas de gestão de quadra pro dono, e o app Flutter em si.

Checklist de QA usado pra validar cada módulo (aplicado nos 4):
- Fluxo feliz ponta a ponta local E em produção
- RBAC negativo: quem não é dono/capitão/organizador recebe 403
- Regra de negócio específica do domínio (ex: reserva duplicada → 409,
  aceitar solicitação recusa as outras, lista de espera promove
  automaticamente quando alguém cancela presença)

---

## 9. Decisões em aberto (ainda não resolvidas)

- Login social Apple — mapeado no código, falta conta paga Apple Developer
- Conta Firebase (Cloud Messaging) — infra pronta, falta criar a conta (6.2)
- Desenho das telas de gestão de quadra pro dono (separado da visualização do jogador)
- Nome de domínio próprio ainda não escolhido/comprado
- CNPJ, Termos de Uso e Política de Privacidade — fora do escopo técnico, status desconhecido
- Início do frontend Flutter — ainda não começou
- Conta Google Play Console — adiada de propósito pro momento de ter build pronta

---

## 10. Convenções e cuidados ao continuar o projeto

- **Nunca** hardcodar segredos de servidor (JWT_SECRET, connection strings
  com senha, service role key) — sempre `process.env`, sempre via `.env`
  git-ignorado ou env vars da plataforma. A chave **anon** do Supabase é
  pública por design e pode aparecer no código do frontend sem problema.
- Migrations: usar `prisma migrate deploy` em produção (não `migrate dev`).
- Supabase: usar sempre o **pooler** pras duas connection strings (ver seção
  3) — o host direto quebra em hosts sem IPv6.
- RBAC: todo endpoint que muda dado de time/quadra precisa checar o contexto
  (é *este* time que o usuário administra?), não só o papel genérico.
- Ao adicionar uma tabela nova, lembrar de declarar a relação Prisma dos dois
  lados.
- Consentimento LGPD sempre como campo explícito e separado, nunca dentro de
  um aceite genérico.

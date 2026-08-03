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
| Backend | NestJS (TypeScript) | Identity/Auth completo (email/senha + Google) |
| ORM / Banco | Prisma + PostgreSQL | Schema completo, migration aplicada |
| Banco hospedado em | **Supabase** (projeto `glgdiymnhmcvzhtmbqqb`) — usar sempre o **pooler** (`aws-1-us-west-2.pooler.supabase.com`): porta 6543 c/ `pgbouncer=true` no `DATABASE_URL`, porta 5432 (session mode) no `DIRECT_URL`. **Nunca** usar o host direto `db.*.supabase.co` — só responde em IPv6, quebra em hosts sem rota IPv6 (ex: Render) | ✅ No ar |
| Host do servidor | **Render** (Web Service free, deploy automático do GitHub) — `https://daleh-fx5c.onrender.com/v1` | ✅ No ar |
| Auth | JWT próprio (email/senha) + login social Google via Supabase Auth (`POST /auth/social`) | Google pronto; Apple mapeado no código mas não habilitado (exige conta paga Apple Developer) |
| Push notifications | Firebase Cloud Messaging (planejado) | Não iniciado |
| Frontend definitivo | **Flutter** (decisão tomada, ainda não iniciado) | Não iniciado |
| Demo web temporário | React + Vite + Tailwind, pasta `daleh-web/` neste mesmo repo | Ver seção 6.1 — **não é o frontend de produção**, é só pra testar/mostrar o que já funciona |
| Protótipo de UX/visual original | React + Tailwind (artifact do Claude, arquivo `fullmatch-core.jsx` em Downloads) | Referência de design pro Flutter — ver seção 6 |

Repositório: `github.com/minatocristofer-dev/DALEH`.

---

## 4. Banco de dados — visão geral

Schema completo em `prisma/schema.prisma`, migration inicial em
`prisma/migrations/20260801140000_init/migration.sql`, **já aplicada** contra
o banco real no Supabase (`prisma migrate deploy` rodado com sucesso).

Tabelas por domínio:

- **Identidade/RBAC**: `users`, `player_profiles`, `modalidades`,
  `player_modalidades`, `player_stats`, `roles`, `user_roles`
- **Times**: `teams`, `team_members`, `team_finances`, `team_challenges`,
  `challenge_requests`, `call_ups`
- **Quadras**: `venues`, `venue_slots`, `bookings`
- **Jogos**: `matches`, `match_attendance`, `match_events`
- **Campeonatos** (schema pronto, fase futura): `championships`,
  `championship_teams`
- **Social/Pagamento/Notificação**: `reviews`, `payments`, `notifications`

**Regra de negócio importante ainda não implementada em código**: ao aceitar uma
`challenge_request`, as demais da mesma `team_challenge` precisam ser recusadas
automaticamente na mesma transação.

**Modalidades**: Futsal (Goleiro, Fixo, Ala, Pivô), Society/Campo 7 (Goleiro,
Zagueiro, Lateral, Meia, Atacante), Campo 11 (Goleiro, Zagueiro, Lateral,
Volante, Meia, Atacante). Populadas via `prisma/seed.ts`.

---

## 5. Backend — o que já existe em código

- `src/modules/identity/` —
  - `POST /v1/auth/register` — cria usuário + perfil + modalidades numa
    transação, estatísticas nascendo zeradas, consentimento LGPD explícito.
  - `POST /v1/auth/login` — e-mail/senha, retorna JWT.
  - `POST /v1/auth/social` — recebe o `access_token` de uma sessão do
    Supabase Auth (Google), verifica via `SupabaseAuthService`
    (`supabase-auth.service.ts`), faz find-or-create do usuário e devolve o
    mesmo formato de JWT dos outros dois endpoints.
- `src/common/guards/roles.guard.ts` + `@Roles()` — RBAC pronto pra usar.
- `src/health.controller.ts` — `GET /v1/` retorna `{status: 'ok', ...}`,
  usado pra checar rapidamente se a API está no ar.
- `prisma/seed.ts` — popula modalidades e papéis de RBAC.

**Módulos ainda não iniciados** (comentário em `app.module.ts`, ordem
recomendada):
1. `TeamsModule` — times + convocação (marco: push notification de verdade)
2. `VenuesModule` — quadras + agenda (separação visualização/gestão)
3. `MatchesModule` — peladas avulsas + marketplace de adversário
4. `NotificationsModule` — Firebase Cloud Messaging

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

Pasta nova neste repo (`daleh-api/daleh-web`), Vite + React + Tailwind,
reaproveitando o visual exato do `fullmatch-core.jsx`, mas com Login/Cadastro
**de verdade** conectados na API (`register`/`login`/`social`). Quadras e
Times continuam com dados fake, iguais ao protótipo original, já que os
módulos de backend deles não existem ainda. Publicado como um Static Site
separado no Render, na mesma conta do backend.

**Propósito**: só validar/demonstrar o que já está funcionando ponta a ponta,
enquanto o Flutter (frontend definitivo) não começa. Não vira produto.

---

## 7. Infraestrutura — estado atual

- **Supabase**: projeto `glgdiymnhmcvzhtmbqqb`, migration aplicada, seed
  rodado. Google habilitado no Supabase Auth (Client ID/Secret configurados
  via Management API). Apple mapeado no código, não habilitado.
- **Render**: Web Service `daleh-api` (free) rodando a API, deploy automático
  a cada push na branch `main`. Variáveis configuradas: `DATABASE_URL`,
  `DIRECT_URL`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `SUPABASE_URL`,
  `SUPABASE_ANON_KEY`. Static Site `daleh-web` publicando o demo (seção 6.1).
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
Times + Convocação  ← marco mais importante: push notification real
        ↓
Quadras (visualização) → Jogos → Quadras (tela de gestão do dono)
        ↓
Notificações push reais (FCM) → Monetização/PRO
        ↓
Frontend definitivo em Flutter (usando fullmatch-core.jsx como referência visual)
```

Checklist de QA definido pra considerar cada fase "pronta":
- Cadastro: fechar e reabrir o app mantém sessão e dados
- Convocação: notificação chega mesmo com o app fechado (não só em primeiro plano)
- RBAC: jogador comum não consegue convocar elenco nem editar time que não é dele
- Disputa (marketplace): aceitar uma solicitação recusa as outras automaticamente
- LGPD: usuário consegue revogar consentimento de geolocalização sem quebrar o cadastro

---

## 9. Decisões em aberto (ainda não resolvidas)

- Login social Apple — mapeado no código, falta conta paga Apple Developer
- Desenho das telas de gestão de quadra pro dono (separado da visualização do jogador)
- Nome de domínio próprio ainda não escolhido/comprado
- CNPJ, Termos de Uso e Política de Privacidade — fora do escopo técnico, status desconhecido
- Início do frontend Flutter — ainda não começou

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

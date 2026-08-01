# DALEH API

Backend real do DALEH — NestJS + PostgreSQL (Prisma). Esta é a "Fundação técnica"
do plano de implementação: por enquanto cobre o schema completo do banco e o módulo de
**Cadastro & Autenticação** (fase 2 do plano).

## Pré-requisitos

- Node.js 20+
- Docker (mais simples) **ou** PostgreSQL já instalado/acessível (local, ou um serviço como Supabase/Neon/Railway)

## Passo a passo

```bash
# 0. Subir o Postgres local (pula este passo se já tiver um banco em outro lugar)
docker compose up -d

# 1. Instalar dependências
npm install

# 2. Configurar variáveis de ambiente
cp .env.example .env
# edite o .env e coloque sua DATABASE_URL real

# 3. Rodar a primeira migration (cria todas as tabelas no banco)
npm run prisma:migrate
# vai pedir um nome pra migration, pode usar algo como "init"

# 4. Popular o banco com as modalidades (Futsal/Society/Campo 11) e papéis de RBAC
npm run prisma:seed

# 5. Subir a API em modo desenvolvimento (recarrega sozinho a cada alteração)
npm run start:dev
```

A API sobe em `http://localhost:3000/v1`.

## Testando o cadastro

```bash
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "João Silva",
    "email": "joao@teste.com",
    "password": "senha12345",
    "city": "Santa Maria",
    "state": "RS",
    "dominantFoot": "Direito",
    "modalidades": [
      { "modalidade": "CAMPO11", "posicaoPrincipal": "Atacante", "posicaoSecundaria": "Meia" }
    ],
    "consentimentoDadosSensiveis": true
  }'
```

Deve voltar um `{ "accessToken": "..." }`. Esse token é o que o app vai guardar e
enviar no header `Authorization: Bearer <token>` nas próximas chamadas.

Pra ver os dados direto no banco sem escrever SQL: `npm run prisma:studio` abre uma
interface visual no navegador.

## O que já está pronto

- Schema completo do banco (todas as tabelas da arquitetura: usuários, modalidades,
  times, convocação, quadras, disputas, campeonatos, pagamentos, notificações)
- Cadastro (`POST /v1/auth/register`) — cria usuário + perfil + modalidades numa
  transação só, com estatísticas nascendo zeradas
- Login (`POST /v1/auth/login`) — retorna JWT
- Guard de RBAC (`RolesGuard` + `@Roles()`) — pronto pra usar nos próximos módulos

## O que falta (próximas fases do plano de implementação)

- [ ] Login social (Google/Apple) — depende de escolher o provedor (Supabase Auth é o
      caminho mais rápido)
- [ ] Módulo de Times (`TeamsModule`) — criar time, elenco, e principalmente a
      **Convocação** com push notification real
- [ ] Módulo de Quadras (`VenuesModule`) — agenda + separação entre tela de jogador
      (visualizar/reservar) e tela de dono (gerenciar)
- [ ] Módulo de Jogos (`MatchesModule`) — peladas avulsas + marketplace de adversário
- [ ] Integração com Firebase Cloud Messaging para notificações push de verdade
- [ ] Testes automatizados de autorização por papel (mencionado como risco no
      documento de arquitetura — RBAC mal testado é a origem mais comum de bug de
      segurança nesse tipo de app)

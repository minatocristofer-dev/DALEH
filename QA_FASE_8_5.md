# DALEH — Ambiente de dados de teste (Fase 8.5)

Gerado por `scripts/seed-qa.ts`, executado contra o backend real (Supabase),
usando exclusivamente os endpoints HTTP já existentes da API. Seguro rodar
de novo (`npx ts-node scripts/seed-qa.ts`) — não duplica nada.

## Contas

| Usuário | E-mail | Senha | Função |
|---|---|---|---|
| Lucas Ferreira | lucas.teste@daleh.local | Daleh@Teste2026! | Capitão — DALEH UNITED |
| Rafael Martins | rafael.teste@daleh.local | Daleh@Teste2026! | Capitão — DALEH FC |
| Gabriel Souza | gabriel.teste@daleh.local | Daleh@Teste2026! | Jogador — DALEH UNITED |
| Matheus Oliveira | matheus.teste@daleh.local | Daleh@Teste2026! | Jogador — DALEH UNITED |
| Pedro Henrique | pedro.teste@daleh.local | Daleh@Teste2026! | Jogador — DALEH FC |
| João Vitor | joao.teste@daleh.local | Daleh@Teste2026! | Jogador — DALEH FC |
| Bruno Almeida | bruno.teste@daleh.local | Daleh@Teste2026! | Sem time — locatário da reserva |
| Marcos Ribeiro | marcos.teste@daleh.local | Daleh@Teste2026! | Dono da quadra (DALEH Arena) |

Todos com cidade "Santa Maria / RS", pé dominante e posição (modalidade
Society) preenchidos — perfil completo pro Player Card. **Sem avatar**: o
cadastro por e-mail/senha não tem upload de foto (só login social preenche
`avatarUrl`) — não inventei um workaround, os 8 aparecem com a inicial do
nome no lugar do avatar, comportamento normal do app.

## Times

| Time | Capitão | Jogadores |
|---|---|---|
| DALEH UNITED | Lucas Ferreira | Lucas Ferreira, Gabriel Souza, Matheus Oliveira |
| DALEH FC | Rafael Martins | Rafael Martins, Pedro Henrique, João Vitor |

## Quadra

**DALEH Arena** — dono: Marcos Ribeiro. Um horário: toda semana no dia de
hoje, 19:00–20:00.

## Reserva

Bruno Almeida reservou o horário acima, na data de hoje. **Status: `pending`
de propósito** — não confirmei automaticamente, é o primeiro teste do
roteiro (dono confirma/recusa).

## Partida

**DALEH UNITED × DALEH FC**, criada pelo fluxo real de desafio (Lucas
publica → Rafael solicita → Lucas aceita), com placar 0×0, `status:
scheduled`. Escalação confirmada no momento em que o seed termina:

- **DALEH UNITED**: Lucas ✅ confirmado · Matheus ✅ confirmado · **Gabriel
  ⏳ convocação pendente** (de propósito)
- **DALEH FC**: Rafael ✅ confirmado · Pedro ✅ confirmado · João ✅ confirmado

## Roteiro manual de QA

Faça login em `daleh.local` como cada usuário na ordem abaixo (todos com a
senha `Daleh@Teste2026!`).

### 1. Confirmar convocação (testa a Fase 8 — Complemento)
**Login: Gabriel Souza.** Aba Times → DALEH UNITED → Convocações (ou Perfil
→ Minhas Convocações) → confirmar a convocação pendente. Depois, abrir a
partida DALEH UNITED × DALEH FC e conferir que Gabriel agora aparece em
"Participantes" — confirma que `CallUp` CONFIRMADO criou o `MatchAttendance`.

### 2. Súmula — gol 1 (0×0 → 1×0)
**Login: Lucas Ferreira.** Abrir a partida → aba SÚMULA → "Registrar gol" →
Quem marcou: **Gabriel Souza** → Assistência: **Matheus Oliveira** →
Registrar. Placar deve virar **1 × 0**.

### 3. Súmula — gol 2 (1×0 → 1×1)
**Login: Rafael Martins.** Mesma partida → SÚMULA → "Registrar gol" → Quem
marcou: **Pedro Henrique** → Assistência: **João Vitor** → Registrar. Placar
deve virar **1 × 1**.

### 4. Testes de segurança (todos devem ser bloqueados)
Ainda antes de finalizar a partida:
- **A.** Login **Gabriel Souza** (jogador comum) → tentar registrar gol → **403**.
- **B.** Login **Lucas** → tentar registrar gol pra um jogador não confirmado
  (nenhum disponível nesse cenário — todos os 6 já estarão confirmados após
  o passo 1; pra testar isso, use qualquer conta nova sem convocação/presença
  na partida) → **bloqueado (400)**.
- **C.** Login **Lucas** → tentar registrar gol pra **Gabriel** com
  assistência de **Pedro Henrique** (time adversário) → **bloqueado (400)**.
- **D.** Login **Bruno Almeida** (sem relação com a partida) → tentar
  registrar gol → **403**.
- **F.** Depois de finalizar a partida (passo 5) → tentar registrar
  qualquer gol → **bloqueado (400)**.

### 5. Finalizar a partida
**Login: Lucas Ferreira** (só o criador finaliza, ver Fase 8 seção 10) →
"Finalizar partida".

### 6. MVP (único — testa bloqueio de segundo MVP)
**Login: Lucas ou Rafael** (qualquer capitão) → "Escolher MVP" → **Gabriel
Souza** → Eleger. Tentar eleger de novo (outro jogador) → **E. bloqueado
(409)**.

### 7. Player Card
**Login: Gabriel Souza** → aba Perfil → conferir Player Card: 1 jogo, 1 gol,
0 assistências, 1 MVP, time DALEH UNITED.
**Login: Matheus Oliveira** → Player Card: 1 jogo, 0 gols, 1 assistência.

### 8. Perfil público
**Login: Lucas** → abrir o perfil de **Gabriel** a partir do elenco do time
ou dos participantes da partida → conferir nome, posição, cidade, time,
estatísticas.
**Login: Rafael** → mesma coisa com **Pedro Henrique**.

### 9. Usuário sem time
**Login: Bruno Almeida** → aba Times deve mostrar "nenhum time" → Perfil
deve funcionar normalmente, sem time nenhum listado.

### 10. Fluxo do locador
**Login: Marcos Ribeiro** → DALEH Arena → aba Reservas → confirmar ou
recusar a reserva do Bruno → conferir notificação recebida pelo Bruno.

### 11. Notificações
Confira a caixa de notificações de cada conta ao longo do roteiro acima —
devem aparecer, no mínimo: convocação (call_up) em todos os 6 jogadores;
pedido de desafio recebido + desafio confirmado (Lucas e Rafael); nova
reserva (Marcos); confirmação/cancelamento de reserva (Bruno, depois do
passo 10).

# DALEH — Checklist de prontidão pro teste interno (Play Store)

> Gerado em 2026-10-25, a partir de auditoria real do código (backend + Flutter), não de suposição. `[x]` = confirmado no código/infra real; `[ ]` = pendente; `[!]` = bloqueado ou precisa de ação manual fora do código.

## 1. Segurança

- [x] `.env` nunca foi commitado (git-ignorado na raiz do repo; só `.env.example` com placeholders está versionado)
- [x] Nenhum segredo jamais apareceu no histórico do git (`.env`, `key.properties`, `*.jks`, `*.keystore` — verificado com `git log --all --full-history`)
- [x] `~/.claude/settings.json` / `settings.local.json` sem segredos (problema identificado em sessão anterior, já resolvido)
- [x] Segredos de produção (`SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`, `DATABASE_URL`, etc.) só existem como env var no Render, nunca no repositório
- [x] `daleh-app/android/.gitignore` (gerado pelo Flutter) já protegia `key.properties`, `*.jks`, `*.keystore`
- [x] `daleh-app/.gitignore` (raiz do app) reforçado hoje com as mesmas 3 regras, por redundância
- [!] Nenhuma keystore de release existe ainda — ver seção 18 (Signing)

## 2. Backend

- [x] 169/169 testes passando (167 pré-existentes + 2 novos de exclusão de conta)
- [x] `tsc --noEmit` limpo, sem erro de tipo
- [x] RBAC contextual (dono/capitão) confirmado nas rotas de escrita de Times/Quadras/Jogos/Desafios/Financeiro
- [x] Bug "Não foi possível salvar a imagem" (avatar) — causa mais provável corrigida (bucket do Supabase Storage criado automaticamente se não existir) e em produção desde 2026-10-16 (deploy `605adad`, status `live`)
- [x] Endpoint de exclusão de conta implementado (`DELETE /v1/auth/me`) — anonimização, não delete físico (ver seção 14)

## 3. Banco/migrations

- [x] `prisma migrate status` contra o banco de produção confirma: **schema em dia**, as 13 migrations aplicadas, incluindo `20261014120000_add_venue_blocked_dates`
- [x] Nenhuma migration pendente de aplicar

## 4. Android

- [x] `applicationId` definitivo: `com.dalehapp.daleh` (marcado no código como "não trocar depois de publicado")
- [x] Permissões mínimas no `AndroidManifest.xml`: só `INTERNET` e `CAMERA` — nenhuma permissão desnecessária (sem localização/armazenamento/contatos)
- [x] Ícone adaptativo gerado (`flutter_launcher_icons`, fundo preto + escudo DALEH) — arquivos confirmados em `mipmap-*`
- [ ] `compileSdk`/`minSdk`/`targetSdk` numéricos — ver seção 20 (Testes), resolvidos depois da instalação do Flutter local

## 5. Build

- [ ] `flutter analyze`/`flutter test` — ver seção 20
- [ ] `flutter build web` / `flutter build apk --debug` — ver seção 21
- [!] `flutter build appbundle --release` hoje cairia pra **assinatura de debug** (sem `key.properties`/keystore) — build resultante não serve pro Play Console

## 6. Autenticação

- [x] Cadastro e-mail/senha (`POST /auth/register`), login (`POST /auth/login`), `GET /auth/me`, login social Google (`POST /auth/social`) — todos confirmados no código
- [x] Onboarding first-run (mostrado uma vez só), Seletor de Modo (aparece em todo login/cadastro novo, nunca em sessão restaurada), restauração do último modo — confirmados no código e validados visualmente no emulador em sessão anterior
- [x] Selecionar modo (Jogador/Dirigente/Locador) **não concede nenhuma permissão de backend** — confirmado no comentário e lógica do código (RBAC é sempre checado pelo backend)
- [x] Exclusão de conta implementada hoje

## 7. Jogador

- [x] Home, Perfil, Player Card, estatísticas, Meus Jogos, Times, Convocações, Quadras, Reservas, Notificações — todas as telas existem e usam dados reais
- [!] Não existe uma tela "Histórico" dedicada — fica implícito em Meus Jogos + estatísticas acumuladas. Não é bloqueador de teste interno, é uma decisão de produto a rever depois.

## 8. Dirigente

- [x] Criar time, elenco, adicionar/remover jogador, convocação, súmula (gols, assistências, cartões, MVP) — confirmados
- [!] Editar nome/cidade/estado do time depois de criado **não existe** (só dá pra editar escudo e número de camisa de membro). Gap de produto, não bloqueador do teste interno.
- [x] Financeiro básico de time (cobrança + chave PIX, módulo `finance`) existe e tem endpoints reais — não expandir, só validar no QA manual

## 9. Locador

- [x] Cadastro/edição de quadra, horários semanais, reservas recebidas, confirmar/recusar/cancelar, bloqueio de datas — confirmados

## 10. Jogos

- [x] Peladas avulsas e desafios entre times (marketplace de adversário) confirmados no backend e no Flutter
- [x] Eventos de súmula (gol/assistência/cartão/MVP) e `MatchEvent.teamId` existem

## 11. Quadras/reservas

- [x] Estados `pending`/`confirmed`/`rejected`/`cancelled` confirmados
- [x] Checagem de disponibilidade/conflito de slot e autorização de dono (`exigirDono`) confirmados no service

## 12. Notificações

- [x] Inbox in-app existe e navega pros destinos corretos (time, convocação, jogo, desafio, quadra, reserva)
- [!] Push real via Firebase ainda não configurado (infraestrutura pronta, falta conta Firebase) — **não é bloqueador do primeiro teste interno**, por decisão explícita desta tarefa

## 13. Perfil/avatar

- [x] Seleção câmera/galeria (com `maxWidth`/`maxHeight` pra evitar OOM em foto de câmera), detecção de rosto (ML Kit), segmentação, composição, preview, upload — fluxo completo validado visualmente em sessão anterior
- [x] Bug de salvar a foto corrigido e em produção (ver seção 2)

## 14. Exclusão de conta

- [x] **Implementada hoje** (não existia antes da auditoria):
  - Backend: `DELETE /v1/auth/me` (`src/modules/identity/auth.controller.ts`), `AuthService.excluirPropriaConta` (`src/modules/identity/auth.service.ts`) — **anonimiza** (e-mail, telefone, senha, nome, foto, cidade, estado, data de nascimento viram nulos/genéricos) em vez de apagar fisicamente, porque `MatchEvent`, `MatchAttendance`, `CallUp`, `TeamCharge`, `Team.ownerId`, `Venue.ownerId` etc. referenciam o usuário sem CASCADE — um delete físico quebraria o histórico esportivo de outras pessoas ou falharia com erro de FK. Tabelas 100% pessoais (`DeviceToken`, `Notification`, `PlayerProfile`) são apagadas de verdade.
  - Flutter: `lib/features/perfil/configuracoes_screen.dart` (nova tela "Configurações", acessível pelo ícone de engrenagem no Perfil) com diálogo de confirmação forte (precisa digitar "EXCLUIR" pra habilitar o botão).
  - Testes novos: 2 no backend (`auth.service.spec.ts`), 2 no controller Flutter (`auth_controller_test.dart`) + 3 na tela (`configuracoes_screen_test.dart`).
- [!] **Não testada em dispositivo real ainda** — rodar o fluxo manualmente antes do teste interno (ver `docs/QA_PLAYSTORE_TEST_PLAN.md`)

## 15. Privacidade/termos

- [x] Rascunhos criados hoje: `docs/PRIVACY_POLICY_DRAFT.md`, `docs/TERMS_OF_USE_DRAFT.md` — baseados só nos dados que o DALEH realmente coleta (ver schema Prisma), precisam de revisão jurídica antes de publicar

## 16. Analytics

- [ ] Nenhum SDK de analytics existe hoje (nem backend, nem Flutter) — nenhum serviço externo foi contratado/configurado, conforme instruído. Arquitetura mínima recomendada documentada abaixo (seção "Recomendação — Analytics").

## 17. Crash reporting

- [ ] Nenhum SDK de crash reporting (Sentry/Crashlytics/Bugsnag) existe hoje — não é bloqueador do teste interno, recomendado antes de um beta mais amplo.

## 18. QA

- [x] Plano de QA manual criado hoje: `docs/QA_PLAYSTORE_TEST_PLAN.md`

## 19. Play Store

- [x] Dados de submissão levantados (rascunho): `docs/PLAYSTORE_SUBMISSION_DATA.md` — **nada foi publicado, nenhum acesso ao Play Console foi feito**

## 20. Store Listing

- [x] Ícone 512x512 / adaptive icon / logo: prontos (`assets/icon/app_icon.png`, `app_icon_foreground.png`)
- [x] Splash screen: pronta (`lib/features/splash/splash_screen.dart`, ainda não commitada)
- [ ] Feature graphic (1024x500): **não existe** — precisa ser criado antes da submissão
- [ ] Screenshots reais da loja (capturas do app rodando): **não existem** — os prints usados até agora são só de QA interno

---

## Recomendação — Analytics (arquitetura mínima, não implementada)

Sem contratar serviço nenhum agora: quando for a hora, o caminho mais simples é `firebase_analytics` (Flutter) + `firebase-admin` (já presente no backend, hoje só usado pro FCM) reaproveitando o mesmo projeto Firebase que será criado pro push real (ver `CLAUDE.md`, seção 6.3). Os eventos já mapeados pra instrumentar nesse momento: `app_opened`, `onboarding_completed`, `signup_completed`, `login_completed`, `mode_selected`, `profile_completed`, `team_created`, `team_joined`, `callup_received`, `callup_accepted`, `callup_declined`, `match_created`, `challenge_created`, `challenge_accepted`, `venue_viewed`, `booking_started`, `booking_created`, `player_card_viewed`, `player_card_shared`.

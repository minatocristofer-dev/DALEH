# DALEH — Dados de submissão pra Play Store (RASCUNHO)

> Nenhum acesso ao Play Console foi feito. Isto é só um documento de preparação com o que já se sabe hoje — campos em branco precisam ser preenchidos antes da submissão real.

## Informações básicas

| Campo | Valor |
|---|---|
| Nome do app | DALEH |
| Application ID (package name) | `com.dalehapp.daleh` — **definitivo, não pode trocar depois de publicado** |
| Categoria sugerida | Esportes |
| Slogan / tagline | "Cada jogo constrói sua história." |
| Versão atual | `1.0.0+1` (`versionName` 1.0.0, `versionCode` 1) |

## Descrições

**Descrição curta** (até 80 caracteres): [preencher]

**Descrição longa** (até 4000 caracteres): [preencher — sugestão de eixo: "o app que organiza futebol amador de ponta a ponta — crie seu time, desafie adversários, reserve quadras e construa seu histórico esportivo com Player Card, estatísticas e súmula digital"]

## Contato e links

| Campo | Valor |
|---|---|
| E-mail de suporte | [preencher] |
| Site | [preencher, se houver] |
| Política de Privacidade (URL pública) | [preencher — publicar `docs/PRIVACY_POLICY_DRAFT.md` revisado num link público antes de submeter] |
| URL de exclusão de conta (Data Safety) | O app já tem exclusão de conta **dentro do app** (Perfil → Configurações → Excluir minha conta) — confirmar se a Google ainda exige uma URL pública equivalente além disso, ou se a opção in-app é suficiente pra este caso |

## Classificação indicativa / público-alvo

- Público-alvo sugerido: adultos e adolescentes que jogam futebol amador (o cadastro pede e-mail e, opcionalmente, data de nascimento — não há verificação de idade mínima implementada hoje; decidir faixa etária alvo antes de preencher o questionário de classificação)
- Conteúdo gerado por usuário: sim (nome, foto, bio, nome de time) — considerar isso no formulário de classificação

## Anúncios

- O app **não tem nenhum SDK de publicidade** — responder "Não" pra anúncios no formulário da Play Store

## Data Safety (formulário de segurança de dados)

Dados coletados (ver `docs/PRIVACY_POLICY_DRAFT.md` pro detalhamento completo):
- Informação pessoal: nome, e-mail, telefone (opcional), data de nascimento (opcional)
- Fotos: foto de perfil
- Localização aproximada: cidade/estado (texto livre, não GPS)
- Atividade do app: times, jogos, convocações, reservas, estatísticas

Compartilhamento com terceiros: **nenhum terceiro além dos provedores de infraestrutura** (Supabase — banco/armazenamento; Render — hospedagem do servidor; Google — login social opcional). Sem SDKs de analytics ou publicidade hoje.

Criptografia em trânsito: sim (HTTPS).

Usuário pode pedir exclusão de dados: sim (dentro do app).

## Credenciais de revisão (pra o revisor da Google testar o app)

Fornecer uma conta de teste pronta, por exemplo (ver `scripts/seed-qa.ts`):
- E-mail: `lucas.teste@daleh.local`
- Senha: [mesma senha das contas seed — **não colar aqui em texto plano no documento final que for enviado à Google**; informar só no campo apropriado do Play Console no momento da submissão]

## Build

- Faixa de teste: Interno (closed testing) — primeiro passo antes de qualquer teste fechado maior
- Formato: Android App Bundle (`.aab`) assinado com a chave de upload — **ver `docs/DALEH_PLAYSTORE_TEST_CHECKLIST.md`, seção 18 (Signing): keystore ainda não existe, precisa ser gerada antes de produzir o AAB final**

---

**NÃO FAZER**: nenhum passo deste documento envolve acessar o Play Console ou publicar nada — é só o levantamento de dados pra quando a submissão de fato acontecer.

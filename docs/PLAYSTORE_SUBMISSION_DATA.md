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

**Descrição curta** (74/80 caracteres):

> Organize peladas, gerencie seu time e reserve quadras — tudo em um só app.

**Descrição longa** (1886/4000 caracteres):

```
CADA JOGO CONSTRÓI SUA HISTÓRIA.

O DALEH é o app que organiza o futebol amador de ponta a ponta — pra quem joga, pra quem gerencia o time e pra quem administra a quadra. Chega de depender só de grupo de WhatsApp pra marcar o próximo jogo.

⚽ PRA QUEM JOGA

• Encontre peladas avulsas perto de você ou desafios entre times
• Confirme presença e acompanhe quem mais vai jogar
• Tenha seu Player Card digital: posição, pé dominante, estatísticas reais (jogos, gols, assistências, cartões, MVPs)
• Construa seu histórico esportivo de verdade — nada de número inventado
• Siga seus parças (outros jogadores) e acompanhe quem mais está em campo
• Compartilhe seu Player Card, a súmula do jogo e a escalação direto nas redes

🛡️ PRA QUEM GERENCIA UM TIME

• Monte seu elenco e convoque os jogadores pra cada jogo
• Desafie outros times e organize confrontos
• Registre a súmula digital: gols, assistências, cartões e MVP, em tempo real
• Acompanhe o dashboard do time: próximo jogo, último resultado, artilheiro, últimas contratações
• Controle cobranças e divisão de custo da quadra entre o elenco
• Compartilhe súmula e escalação com o grupo

🏟️ PRA QUEM TEM UMA QUADRA

• Cadastre sua quadra, seus horários e sua disponibilidade
• Receba e gerencie reservas direto pelo app — confirme, recuse ou cancele
• Marque horários fixos pra clientes recorrentes
• Acompanhe o dashboard: ocupação, reservas do dia e do mês
• Bloqueie datas quando a quadra não estiver disponível

Mesma conta, três jeitos de usar — você pode trocar de modo (Jogador, Dirigente ou Locador) a qualquer momento, sem precisar de outra conta.

O DALEH não é só um app de organizar jogo. É onde o seu futebol vira história de verdade: cada gol, cada assistência, cada jogo disputado fica registrado — o seu "currículo" dentro de campo, pra você mostrar com orgulho.

Baixe agora e comece a construir sua história no DALEH.
```

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

Compartilhamento com terceiros: provedores de infraestrutura (Supabase — banco/armazenamento; Render — hospedagem do servidor; Google — login social opcional) **+ Firebase Analytics** (Google) desde 05/11/2026 — eventos de uso (abrir app, cadastro, login, criar time/jogo, reserva, compartilhamento), sem dado de anúncio. Precisa declarar isso no formulário de Data Safety (categoria "App activity" compartilhada com a Google/Firebase). Sem SDK de publicidade.

Criptografia em trânsito: sim (HTTPS).

Usuário pode pedir exclusão de dados: sim (dentro do app).

## Credenciais de revisão (pra o revisor da Google testar o app)

Fornecer uma conta de teste pronta, por exemplo (ver `scripts/seed-qa.ts`):
- E-mail: `lucas.teste@daleh.local`
- Senha: [mesma senha das contas seed — **não colar aqui em texto plano no documento final que for enviado à Google**; informar só no campo apropriado do Play Console no momento da submissão]

## Build

- Faixa de teste: Interno (closed testing) — primeiro passo antes de qualquer teste fechado maior
- Formato: Android App Bundle (`.aab`) assinado com a chave de upload — **confirmado funcionando em 07/11/2026**: keystore real existe, `flutter build appbundle --release` gera `app-release.aab` assinado de verdade (certificado `CN=DALEH, O=DALEH, Santa Maria/RS/BR`), não mais a chave de debug. Build mais recente salvo em `C:\Users\minat\Downloads\DALEH-release.aab`.

## Assets de loja

- **Ícone 512×512**: pronto (`daleh-app/assets/icon/app_icon.png`)
- **Feature graphic 1024×500**: pronto, gerado e conferido — `docs/store-assets/feature-graphic-1024x500.png`
- **Screenshots reais do app**: prontas — 5 capturas de verdade (emulador, conta de teste seed, sem nenhum dado pessoal real), `docs/store-assets/screenshots/`:
  - `daleh-screenshot-00-login.png` — tela de login
  - `daleh-screenshot-01-home.png` — Home do Jogador (mostra inclusive o "local livre" de jogo avulso, "Quadra do Basso")
  - `daleh-screenshot-02-perfil.png` — Perfil / Player Card
  - `daleh-screenshot-03-times.png` — Meus Times (modo Dirigente)
  - `daleh-screenshot-04-locador.png` — Minhas Quadras (modo Locador)
  - Cópia idêntica também em `C:\Users\minat\Downloads\` pra upload direto no Play Console

---

**NÃO FAZER**: nenhum passo deste documento envolve acessar o Play Console ou publicar nada — é só o levantamento de dados pra quando a submissão de fato acontecer.

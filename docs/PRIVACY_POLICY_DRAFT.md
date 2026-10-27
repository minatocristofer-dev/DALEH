# Política de Privacidade do DALEH — RASCUNHO

> **Este é um rascunho técnico pra revisão jurídica antes de publicar.** Foi montado só a partir dos dados que o código do DALEH efetivamente coleta e dos serviços externos que ele efetivamente usa (confirmado olhando `prisma/schema.prisma` e as dependências reais do projeto) — nada aqui foi inventado ou "preenchido por precaução". Antes de publicar, um advogado precisa revisar a redação final e confirmar adequação à LGPD e às políticas de Data Safety da Google Play.

**Última atualização:** [preencher na publicação]

## 1. Quem somos

O DALEH é um aplicativo que organiza futebol amador — times, jogos, quadras e o histórico esportivo do jogador. Esta política explica quais dados coletamos, por quê, e como você pode controlá-los.

## 2. Dados que coletamos

### 2.1 Dados de cadastro e perfil (diretamente de você)
- Nome completo
- E-mail
- Telefone (opcional)
- Cidade e estado
- Data de nascimento (opcional, usada só pra calcular idade exibida no seu perfil)
- Foto de perfil (processada no próprio aparelho — detecção de rosto e remoção de fundo rodam localmente, nunca em servidor externo — e depois enviada pro nosso servidor)
- Pé dominante, biografia curta, nível de habilidade (todos opcionais)

### 2.2 Dados de atividade esportiva (gerados pelo uso do app)
- Times que você participa ou administra
- Jogos e peladas em que você confirma presença
- Estatísticas (gols, assistências, cartões, MVPs) registradas em súmulas de partidas
- Convocações recebidas/respondidas
- Reservas de quadra feitas ou recebidas (se você for dono de quadra)
- Cobranças de time e status de pagamento, quando o time usa essa função

### 2.3 Dados técnicos
- Token de sessão (pra manter você logado)
- Token de notificação push do dispositivo (quando a função de notificações push estiver habilitada)

## 3. Como usamos seus dados

Usamos seus dados exclusivamente para:
- Criar e manter sua conta e seu histórico esportivo (o "Strava do futebol amador" é o conceito central do produto — ver `CLAUDE.md`)
- Conectar você a times, jogos e quadras
- Mostrar seu Player Card e estatísticas pra você e pros outros usuários do app
- Processar reservas de quadra e convocações de time
- Enviar notificações relacionadas à sua atividade (convocação, resultado de reserva, etc.)

**Não vendemos nem alugamos seus dados pessoais a terceiros.** Não usamos seus dados para publicidade direcionada — o app não tem nenhum SDK de anúncios ou rastreamento publicitário.

## 4. Com quem compartilhamos dados

### 4.1 Outros usuários do app
Seu nome, foto, posição, cidade/estado, estatísticas e histórico de times/jogos são visíveis para qualquer outro usuário autenticado do DALEH (perfil público) — isso é inerente ao produto: um Player Card compartilhável e um histórico esportivo público entre jogadores. Seu e-mail e telefone **nunca** são mostrados no perfil público.

### 4.2 Provedores de infraestrutura (processadores de dados, não terceiros que "usam" seus dados por conta própria)
- **Supabase** (banco de dados PostgreSQL e armazenamento de arquivos) — hospeda todos os dados do app, incluindo sua foto de perfil.
- **Render** — hospeda o servidor (API) do DALEH.
- **Google (Firebase/Google Sign-In)** — usado para login social opcional via conta Google. Se você usa essa opção, o Google compartilha conosco seu e-mail e nome, conforme autorizado por você no momento do login.

Nenhum outro serviço de terceiros (analytics, publicidade, rastreamento) está integrado ao app hoje.

## 5. Processamento no seu aparelho

A foto de perfil passa por detecção de rosto e remoção de fundo **inteiramente no seu aparelho**, usando Google ML Kit — a imagem original só é enviada pro servidor depois de processada, e só a versão final (rosto sobre o fundo padrão do DALEH) é armazenada.

## 6. Quanto tempo guardamos seus dados

Guardamos seus dados enquanto sua conta existir. Dados de histórico esportivo que fazem parte de atividades compartilhadas com outras pessoas (uma súmula de jogo, uma convocação de time) continuam existindo mesmo depois que você exclui sua conta, mas **sem nenhum dado que te identifique** (ver seção 7).

## 7. Como excluir sua conta e seus dados

Você pode excluir sua conta a qualquer momento dentro do app, em **Perfil → Configurações (ícone de engrenagem) → Excluir minha conta**. A exclusão:
- Remove permanentemente seu nome, e-mail, telefone, foto, cidade, estado e data de nascimento
- Torna sua conta impossível de acessar novamente
- Remove suas notificações e token de dispositivo imediatamente

Por motivo técnico, registros de atividade que outras pessoas compartilham com você (por exemplo, a súmula de um jogo em que você participou, ou uma convocação de time) **não são apagados fisicamente** — eles permanecem como parte do histórico do time/jogo pra outras pessoas, mas completamente desvinculados da sua identidade (sem seu nome, e-mail ou qualquer dado pessoal).

[Link de exclusão de conta fora do app — preencher se a Google exigir uma URL pública além da opção dentro do app]

## 8. Seus direitos (LGPD)

Você pode, a qualquer momento:
- Acessar os dados que temos sobre você (tela de Perfil, dentro do app)
- Corrigir dados incorretos (editar perfil, dentro do app)
- Excluir sua conta (ver seção 7)
- Pedir uma cópia dos seus dados — entre em contato: [e-mail de suporte — preencher]

## 9. Contato

Dúvidas sobre esta política ou sobre seus dados: [e-mail de suporte — preencher]

---

**Nota para quem for publicar**: campos marcados `[preencher]` precisam de valor real antes da publicação. Esta política cobre só o que o código confirma hoje — qualquer integração nova (analytics, push real, pagamentos) exige atualizar este documento antes de ir ao ar.

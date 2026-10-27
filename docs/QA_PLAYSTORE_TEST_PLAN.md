# DALEH — Plano de QA manual pro teste interno

> Checklist de missões manuais pra rodar num aparelho real antes de liberar o teste interno na Play Store. Complementa os testes automatizados (`flutter test` / `npx jest`), que cobrem lógica, não a experiência de ponta a ponta no aparelho.

## Pré-requisitos

- APK de debug ou internal-testing instalado num aparelho Android real (não só emulador)
- Pelo menos 2 contas de teste (ver `scripts/seed-qa.ts` / `QA_FASE_8_5.md` pra contas já seedadas) — times/jogos envolvendo mais de uma pessoa não dá pra testar sozinho
- Conexão de internet normal + um jeito de simular internet lenta/offline (modo avião, throttling do Android)

## Missão 1 — JOGADOR

- [ ] Cadastro (3 passos) com e-mail/senha novo
- [ ] Onboarding aparece só na primeira abertura (reabrir o app depois não deve mostrar de novo)
- [ ] Login social com Google funciona e cai direto no Seletor de Modo
- [ ] Trocar a foto de perfil: câmera **e** galeria, confirmar que a foto final mostra rosto real sobre o fundo padrão do DALEH
- [ ] Editar perfil (cidade, estado, pé dominante, bio)
- [ ] Entrar num time existente (convite por e-mail) ou criar um time próprio
- [ ] Receber e responder uma convocação (aceitar e recusar, em execuções separadas)
- [ ] Ver o Player Card com estatísticas reais (não inventadas) e compartilhar
- [ ] Ver histórico de jogos (Meus Jogos) depois de participar de pelo menos um
- [ ] Buscar e reservar uma quadra; acompanhar o status da reserva (pendente → confirmada/recusada)
- [ ] Abrir a inbox de notificações e confirmar que cada notificação leva pro destino certo (convocação → tela da convocação, reserva → tela da reserva, etc.)
- [ ] **Excluir a própria conta** (fluxo novo): confirmar que pede a palavra "EXCLUIR", que desloga de verdade, e que não é mais possível logar com o e-mail antigo depois

## Missão 2 — DIRIGENTE

- [ ] Criar um time novo
- [ ] Adicionar jogador ao elenco (por e-mail)
- [ ] Definir número de camisa e remover um jogador do elenco
- [ ] Convocar o elenco pra um jogo
- [ ] Criar um desafio contra outro time (ou aceitar um recebido)
- [ ] Registrar uma súmula completa: gols, assistências, cartão amarelo, cartão vermelho, eleger o MVP
- [ ] Conferir que as estatísticas da súmula aparecem certas no Player Card de cada jogador envolvido
- [ ] Testar cobrança de time (PIX/financeiro básico), se o time usar essa função
- [ ] Trocar pro modo Locador/Jogador e voltar pro Dirigente sem perder o time selecionado

## Missão 3 — LOCADOR

- [ ] Cadastrar uma quadra nova (nome, endereço, características, preço)
- [ ] Configurar horários semanais recorrentes
- [ ] Bloquear uma data específica (feriado, manutenção)
- [ ] Receber uma reserva de outro usuário de teste e confirmar
- [ ] Receber outra reserva e recusar
- [ ] Cancelar uma reserva já confirmada
- [ ] Editar informações da quadra depois de criada

## Missão 4 — Condições adversas

- [ ] Internet lenta: confirmar que telas mostram loading em vez de travar/crashar
- [ ] Sem internet (modo avião): confirmar mensagem de erro clara, sem crash, e que a tela se recupera ao reconectar
- [ ] Fechar o app no meio de uma ação (ex: no meio do upload de uma foto) e reabrir — não deve ficar em estado inconsistente
- [ ] Logout e login de novo com a mesma conta — dados batem com antes
- [ ] Testar em aparelho de tela pequena (ou emulador configurado pra isso) — sem corte de texto/botão fora da tela
- [ ] Teclado aberto não esconde campo obrigatório em nenhum formulário (cadastro, criar time, criar quadra)
- [ ] Rolagem (scroll) funciona em todas as listas longas (elenco grande, muitos jogos, muitas quadras)
- [ ] Desinstalar e reinstalar o app — volta pro estado de "primeira abertura" (onboarding aparece de novo, login pedido de novo)

## Missão 5 — Regressão rápida (coisas que já quebraram antes em QA real, segundo comentários no código)

- [ ] Botão "Sair" aparece mesmo quando o perfil falha ao carregar
- [ ] Cabeçalho do login/cadastro mostra o texto certo pra cada tela ("Entre na sua conta" vs "Crie sua conta")
- [ ] Telefone repetido no cadastro mostra erro claro (não um 500 genérico)
- [ ] "Jogos disputados" não conta partida cancelada nem partida futura
- [ ] Foto tirada direto da câmera (não da galeria) não derruba o app — teste explicitamente esse caminho, foi uma causa real de crash corrigida recentemente

## Como reportar um problema encontrado

Pra cada item que falhar: anotar a missão, o passo exato, o que era esperado vs. o que aconteceu, e se possível um print/vídeo. Problemas que impedem completar uma missão inteira = bloqueador (P0); problemas visuais/de usabilidade que não impedem completar = P1/P2.

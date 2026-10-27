# DALEH — QA Round 2 (pós-correções)

> Roteiro de teste manual em aparelho real pras mudanças desta rodada (Prioridades 1–5). Complementa `docs/QA_PLAYSTORE_TEST_PLAN.md` (não substitui).

## JOGADOR

- [ ] Onboarding mostra as 3 telas novas na ordem: ENCONTRE SEU JOGO → GERENCIE SEU TIME → CONTROLE SUA QUADRA
- [ ] Ícone do app no launcher preenche o quadrado (não aparece mais pequeno/centralizado com borda preta)
- [ ] Login
- [ ] **Foto da câmera**: tirar foto na hora não derruba mais o app; se algo der errado, aparece mensagem específica (não genérica)
- [ ] **Foto da galeria**: escolher foto existente funciona normalmente
- [ ] Salvar a foto processada, fechar e reabrir o app — a foto persiste
- [ ] Perfil mostra posição, pé preferencial e número da camisa corretamente (quando o jogador tem time)
- [ ] Editar apelido em Configurações — aparece no Player Card entre aspas, abaixo do nome
- [ ] **Parças**: seguir um jogador a partir do perfil público dele (botão "SEGUIR (PARÇA)"), confirmar que aparece na aba SEGUINDO em Configurações → Parças
- [ ] Deixar de seguir — some da lista
- [ ] **Histórico** (antiga aba "Jogos", agora sem o sub-menu Desafios): mostra próximos e encerrados, com placar/status
- [ ] **Fale Conosco**: enviar uma mensagem de teste (categoria + assunto + mensagem), confirma toast de sucesso
- [ ] Wordmark "DALEH" aparece no canto superior esquerdo da Home, estilo consistente com o Player Card

## DIRIGENTE

- [ ] Aba "VISÃO GERAL" do time mostra o PAINEL novo: jogos/gols/elenco, próximo jogo, último jogo (com placar quando já ocorreu), artilheiro, última contratação
- [ ] Painel não quebra/trava quando o time ainda não tem nenhum jogo ou gol (tudo some graciosamente, sem erro feio)
- [ ] Convocação, súmula (gol/assistência/cartão/MVP) continuam funcionando como antes
- [ ] Apelido do artilheiro/última contratação aparece quando definido (em vez do nome completo)

## LOCADOR

- [ ] Nova aba "PAINEL" na tela da quadra: reservas hoje, horários livres hoje, ocupação do mês, reservas do mês, valor em reservas (hoje e mês), time mais frequente
- [ ] Painel não mostra "R$ recebido" nem confirma pagamento — só "valor em reservas" (reservas existem, pagamento real ainda é fora do app)
- [ ] Abrir uma quadra via notificação de nova reserva ainda cai na aba RESERVAS certa (não mudou de comportamento pro usuário, só o índice interno)
- [ ] Horário fixo: marcar uma reserva existente como fixa (endpoint `PATCH /bookings/:id/fixed` — **ainda sem botão na UI nesta rodada**, testável via API/Postman por enquanto) bloqueia esse mesmo horário em datas futuras na tela de disponibilidade

## Regressão rápida (não deve ter mudado)

- [ ] Cadastro, login, seletor de modo, troca de modo — sem alteração de comportamento
- [ ] Reservar quadra como jogador continua funcionando
- [ ] Compartilhar Player Card continua funcionando (serviço de share foi refatorado, mas o comportamento é o mesmo)

## Limitações conhecidas desta rodada (ver relatório `# DALEH — QA ROUND 2` para detalhes completos)

- Calendário/agenda visual do Locador (referência enviada) não foi reconstruído — o Painel novo é só o resumo numérico
- Botão de "marcar horário fixo" ainda não existe na UI do Locador (endpoint pronto no backend)
- Cards de compartilhar Súmula/Escalação/Confronto (imagem estilo Player Card) não foram criados — o serviço de share comum já existe e está pronto pra isso
- Editar nome/cidade/estado do time depois de criado continua não existindo

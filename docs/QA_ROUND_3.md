# DALEH — QA manual Round 3

> Checklist de teste manual em aparelho/emulador real, por papel. Cobre só
> o que foi concluído nesta rodada — os fluxos já validados na Round 2 (ver
> `QA_ROUND_2.md`) continuam valendo e não precisam ser repetidos aqui.

## JOGADOR

- [ ] Foto: tirar foto / escolher da galeria, ajustar, salvar — mensagem
      clara em cada erro possível (permissão negada, timeout, falha ao
      processar).
- [ ] Apelido: editar em Configurações, aparece no Player Card entre aspas
      e substitui o nome na escalação/súmula quando preenchido.
- [ ] Posição e pé dominante: editar, refletido no Player Card.
- [ ] Camisa: trocar de estilo, aparece no Player Card.
- [ ] Parças: tela com abas SEGUINDO/SEGUIDORES; seguir/deixar de seguir a
      partir do perfil público de outro jogador; a lista atualiza.
- [ ] Fale Conosco: escolher categoria, escrever assunto/mensagem, enviar
      — confirmação visual, sem erro.
- [ ] Meus Jogos: só existe um fluxo chamado "Meus Jogos" na navegação
      (não existe mais "Histórico"/"Jogos"/"Desafios" visível pro
      Jogador).
- [ ] Onboarding (primeira vez só): 3 telas na ordem JOGADOR →
      DIRIGENTE → LOCADOR, imagem ocupando a tela inteira, sem texto
      cortado, Pular/dots/botão legíveis por cima.

## DIRIGENTE

- [ ] Dashboard do time: abrir um time, ver jogos/gols/elenco, próximo
      jogo, último jogo (com placar), artilheiro, última contratação —
      cada card só aparece quando há dado real.
- [ ] Súmula de um jogo finalizado: botão "COMPARTILHAR SÚMULA" abre uma
      prévia com escudo/nome dos times, placar, gols em ordem
      cronológica, cartões resumidos e MVP (quando eleito); ao confirmar,
      abre a folha de compartilhamento nativa do aparelho.
- [ ] Escalação: na aba Participantes de um jogo com confirmados, botão
      "COMPARTILHAR ESCALAÇÃO" abre uma prévia com confronto (ou
      modalidade, se avulso), data/hora/local e os confirmados agrupados
      por GOLEIROS/DEFENSORES/MEIAS/ATACANTES.

## LOCADOR

- [ ] Calendário: aba Painel mostra a faixa de 14 dias a partir de hoje,
      tocar num dia troca a agenda carregada abaixo sem travar.
- [ ] Agenda do dia: cada horário aparece com o estado certo — LIVRE
      (lima), RESERVADO (âmbar, com o nome de quem reservou), FIXO (azul,
      com o nome do time/grupo fixo); se a data inteira estiver
      bloqueada, aparece o aviso de bloqueio no lugar da agenda.
- [ ] Horário fixo: num horário RESERVADO, tocar no cadeado abre o
      diálogo de marcar como fixo (nome do time/grupo é opcional);
      depois de confirmar, o horário passa a aparecer como FIXO na
      agenda.
- [ ] Remover horário fixo: num horário FIXO, tocar no cadeado e
      confirmar a remoção — volta a aparecer como RESERVADO.
- [ ] Autorização: só o dono da quadra vê a ação de marcar/remover fixo
      (não existe caminho pra outro usuário chamar essa ação pela UI).
- [ ] Dashboard: resumo do mês (reservas hoje/mês, livres hoje, ocupação,
      valor em reservas hoje/mês — nunca "valor recebido", não existe
      pagamento online) continua aparecendo abaixo da agenda.
- [ ] Reservas recebidas: confirmar/recusar reserva pendente continuam
      funcionando como antes.
- [ ] Compartilhar confronto: numa reserva recebida, tocar no ícone de
      compartilhar abre a prévia do card (quem reservou ou o nome do
      time fixo, nome da quadra, data e horário) antes de abrir a folha
      de compartilhamento nativa.

## Pontos de atenção gerais

- Nenhum card de compartilhamento deve duplicar informação já visível na
  tela por trás — eles só aparecem dentro da prévia (folha modal), não
  ficam cravados na tela principal.
- Testar a agenda do Locador num dia sem nenhum horário cadastrado (deve
  mostrar o aviso "Nenhum horário cadastrado", não uma tela em branco).
- Testar a agenda num dia com todos os horários livres, todos reservados e
  misturados, pra conferir as cores/ícones lado a lado.

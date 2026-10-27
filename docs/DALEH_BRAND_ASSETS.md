# DALEH — Inventário de assets de marca

> Auditoria feita na QA Round 3, item 8. Lista o que existe hoje, qual é o
> oficial e o que está deprecado — sem apagar nada sem conferir referências
> primeiro.

## 1. App icon (oficial)

- **Fonte**: `daleh-app/assets/icon/app_icon.png` (ícone legacy/fallback,
  1536×1536, full-bleed) e `daleh-app/assets/icon/app_icon_foreground.png`
  (mesma arte, usada como foreground do ícone adaptativo do Android).
- **Geração**: `dart run flutter_launcher_icons`, configurado em
  `daleh-app/pubspec.yaml` (seção `flutter_launcher_icons:`). Fundo do ícone
  adaptativo: preto sólido (`#000000`). **Sempre que o PNG de origem mudar,
  rodar esse comando de novo** — ele não roda sozinho no build normal.
- **Auditoria desta rodada**: o ícone novo (cheio, sem borda) tinha sido
  trocado em `assets/icon/` numa rodada anterior, mas o comando de geração
  nunca tinha sido rodado de novo depois dessa troca — os arquivos nativos
  Android (`android/app/src/main/res/mipmap-*/ic_launcher.png` e
  `drawable-*/ic_launcher_foreground.png`) ainda estavam com a versão
  antiga. Corrigido nesta rodada: comando rodado, arquivos nativos
  atualizados. Além disso, o XML do ícone adaptativo
  (`mipmap-anydpi-v26/ic_launcher.xml`) tinha um `inset` de 16% aplicado por
  padrão pelo pacote — isso encolhia o ícone por cima da máscara
  circular/squircle do launcher, mesmo a arte já sendo full-bleed (era
  exatamente o "ícone pequeno" relatado em QA). Adicionado
  `adaptive_icon_foreground_inset: 0` na config — o XML agora usa `inset:
  0%` (o Android já garante sozinho a área de segurança central de 66,7%,
  então zerar o inset do pacote não corta conteúdo crítico).
- **Arquivos gerados** (não editar manualmente — sempre regerar a partir do
  PNG de origem): `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`,
  `android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png`,
  `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`,
  `android/app/src/main/res/values/colors.xml` (cor de fundo do adaptativo).

## 2. Wordmark "DALEH"

- **Não existe asset gráfico** (PNG/SVG) da wordmark isolada — ela é
  renderizada como texto, via o componente `lib/shared/widgets/daleh_wordmark.dart`
  (`DalehWordmark`): `Text('DALEH', style: TextStyle(fontWeight: w900,
  fontStyle: italic, letterSpacing: size*0.05))`, cor lima por padrão,
  fonte do sistema (sem fonte customizada embarcada no projeto).
- **Auditoria desta rodada (item 7)**: a referência visual (itálico,
  esportivo, peso alto, lima) é aproximada razoavelmente bem pela
  combinação `FontWeight.w900` + `FontStyle.italic` + letter-spacing, que é
  a mesma abordagem já usada no app pra outros textos de destaque (placar,
  títulos). Não existe, nos assets do projeto, nenhuma fonte customizada
  nem um arquivo de wordmark pronto (vetorial ou raster) — criar uma fonte
  ou um arquivo gráfico novo está fora do que foi pedido ("não inventar
  asset que não existe"). **Decisão**: manter `DalehWordmark` como texto
  (não há asset gráfico pra substituí-lo por uma `Image`), documentado aqui
  como ponto em aberto — se um dia existir uma wordmark vetorial oficial
  (arquivo gráfico desenhado por um designer), trocar a implementação
  interna de `DalehWordmark` por `Image.asset(...)` é a única mudança
  necessária, já que todo o app já consome o componente, não o texto cru.
- **Usado em**: cabeçalho de login/cadastro (`app.dart`), Início do Jogador
  (`inicio_screen.dart`), Player Card (`player_card.dart`), súmula
  (`sumula_widgets.dart`), reserva do jogador (`minha_reserva_screen.dart`)
  e nos 3 novos cards de compartilhamento desta rodada (súmula, escalação,
  confronto da quadra).

## 3. Escudo (shield) "DALEH"

- O desenho do escudo (preto/lima, bola de futebol, campo estilizado) existe
  **só** como o PNG de origem do app icon (`assets/icon/app_icon.png` /
  `app_icon_foreground.png`) — não há um arquivo separado dele pro app usar
  como ilustração em outras telas. Nenhuma tela do app hoje usa esse escudo
  fora do ícone do launcher.

## 4. Splash screen

- Usa o `launch_background.xml` padrão gerado pelo `flutter create`
  (`android/app/src/main/res/drawable{,-v21}/launch_background.xml`) — cor
  de fundo sólida, sem logo nem escudo desenhado nela. Não existe asset de
  splash customizado no projeto (nem duplicado, nem oficial) — está fora do
  escopo desta rodada criar um.

## 5. Assets antigos/deprecados

- Nenhum PNG de versão antiga do ícone sobrou em `assets/icon/` — a pasta
  só tem os 2 arquivos oficiais atuais (`app_icon.png`,
  `app_icon_foreground.png`). Os arquivos nativos antigos em
  `android/app/src/main/res/mipmap-*` e `drawable-*` eram cópias
  **geradas** da versão anterior do ícone (não é um asset de origem
  separado) — foram sobrescritos nesta rodada pelo regerador, não exigem
  limpeza manual.
- Não foi encontrado nenhum outro arquivo de logo/wordmark/ícone duplicado
  ou órfão no repositório (`daleh-app/assets/`, `daleh-web/`, raiz do
  projeto).

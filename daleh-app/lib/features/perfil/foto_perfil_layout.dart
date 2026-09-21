/// Proporção do quadro da foto de perfil (jogador + camisa do DALEH) — usada
/// tanto em `EditarFotoScreen` (onde a foto é composta) quanto em
/// `PlayerCard` (onde o resultado final aparece), pra uma bater com a outra.
const aspectoFotoPerfil = 0.85;

/// Fração da altura do quadro ocupada pela camisa — ela fica como uma faixa
/// fixa na base, nunca cobrindo mais que isso. Pedido explícito do usuário
/// em QA (2026-09-21): a camisa "espremia" o rosto numa fresta pequena;
/// agora é o contrário, a foto ocupa o quadro inteiro e a camisa é só uma
/// moldura na parte de baixo.
const fracaoCamisaFotoPerfil = 1 / 3;

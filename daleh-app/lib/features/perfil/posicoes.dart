/// Posições por modalidade — espelha exatamente o seed do backend
/// (`prisma/seed.ts`, `Modalidade.positions`). Mesma lista usada no cadastro
/// (`CadastroScreen`) e na edição de posição no Perfil, pra nunca divergir.
const posicoesPorModalidade = {
  'FUTSAL': ['Goleiro', 'Fixo', 'Ala', 'Pivô'],
  'SOCIETY': ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante'],
  'CAMPO11': ['Goleiro', 'Zagueiro', 'Lateral', 'Volante', 'Meia', 'Atacante'],
};

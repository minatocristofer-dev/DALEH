/// Tempo de casa no time, no estilo "LinkedIn" (referência de produto usada
/// desde o início do DALEH: "LinkedIn + Strava do futebol amador") — em vez
/// de só cravar a data, diz há quanto tempo o jogador está lá. `desde` vem
/// de `TeamMember.criadoEm`/`MeuPerfil.timesAtuais[].desde`, que é `null`
/// pra quem já estava no elenco antes dessa fase (nunca inventado — ver
/// schema.prisma). Quem chama decide o que fazer com `null` (normalmente:
/// não mostrar nada).
String tempoNoTime(DateTime desde, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();

  var meses = (hoje.year - desde.year) * 12 + (hoje.month - desde.month);
  if (hoje.day < desde.day) meses--;
  if (meses < 1) return 'Novo no time';

  if (meses < 12) return 'Há $meses ${meses == 1 ? 'mês' : 'meses'} no time';

  final anos = meses ~/ 12;
  final mesesRestantes = meses % 12;
  final parteAnos = 'Há $anos ${anos == 1 ? 'ano' : 'anos'}';
  if (mesesRestantes == 0) return '$parteAnos no time';
  return '$parteAnos e $mesesRestantes ${mesesRestantes == 1 ? 'mês' : 'meses'} no time';
}

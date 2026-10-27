import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

/// Assinatura tipográfica oficial da marca DALEH — sempre que a palavra
/// "DALEH" aparece sozinha pra identificar a marca (não dentro de uma frase
/// normal como "Bem-vindo ao DALEH"), usa este componente em vez de um
/// `Text('DALEH')` solto, pra garantir fonte/peso/inclinação/cor idênticos
/// em qualquer tela (Home, Player Card, súmula, cabeçalho de login, etc.).
///
/// Fonte: nenhuma fonte customizada foi encontrada nos assets do projeto
/// pro wordmark do mockup aprovado — em vez de escolher uma fonte externa
/// aleatória, reaproveita a fonte padrão do sistema (já usada em todo o
/// app) com peso máximo (w900) + itálico + tracking, que é o estilo mais
/// próximo da referência (esportivo, técnico, com sensação de velocidade)
/// sem adicionar nenhuma dependência nova.
class DalehWordmark extends StatelessWidget {
  final double size;
  final Color color;
  const DalehWordmark({super.key, this.size = 19, this.color = DalehColors.turf});

  @override
  Widget build(BuildContext context) {
    return Text(
      'DALEH',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: size,
        letterSpacing: size * 0.05,
        height: 1,
      ),
    );
  }
}

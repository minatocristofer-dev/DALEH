import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

/// Escudo do time (ou avatar de jogador) — mostra a imagem se houver URL,
/// senão um placeholder com a inicial do nome. Nunca quebra o layout quando
/// o campo não existe (times/jogadores sem foto são o caso comum hoje).
class CrestAvatar extends StatelessWidget {
  final String? url;
  final String nome;
  final double tamanho;

  const CrestAvatar({super.key, required this.url, required this.nome, this.tamanho = 44});

  @override
  Widget build(BuildContext context) {
    final inicial = nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(tamanho / 3),
        child: Image.network(
          url!,
          width: tamanho,
          height: tamanho,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(inicial),
        ),
      );
    }
    return _placeholder(inicial);
  }

  Widget _placeholder(String inicial) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: DalehColors.surface2,
        borderRadius: BorderRadius.circular(tamanho / 3),
        border: Border.all(color: DalehColors.line),
      ),
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: tamanho * 0.4),
      ),
    );
  }
}

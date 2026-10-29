import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ícone "G" multicolorido do Google, desenhado via `CustomPainter` — não
/// existe asset nem pacote de ícone do Google neste projeto, e abrir uma
/// dependência nova só pra um ícone de ~20px não compensa.
class GoogleGIcon extends StatelessWidget {
  final double size;
  const GoogleGIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GoogleGPainter()));
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 4 arcos de 90° cada (soma exata de 2π, sem sobra/gap), começando no
    // topo e andando no sentido horário — aproximação das cores reais da
    // marca Google, não precisa ser pixel-perfect num ícone deste tamanho.
    final quarto = math.pi / 2;
    var inicio = -math.pi / 2;
    for (final cor in const [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)]) {
      canvas.drawArc(rect, inicio, quarto, false, paint..color = cor);
      inicio += quarto;
    }

    // Haste horizontal azul do centro até a borda direita — fecha o "G"
    // (sem ela fica só um anel colorido, sem a abertura característica).
    final barra = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - strokeWidth / 2, center.dy - strokeWidth / 2, radius + strokeWidth, strokeWidth),
      barra,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';
import 'foto_perfil_layout.dart';

/// Marcas de enquadramento sobre o card da foto de perfil: cantos de visor
/// na área da foto, um círculo na altura da cabeça e linhas tracejadas de
/// centralização. Só orientação na tela — fica fora do RepaintBoundary, então
/// nunca entra no PNG final.
class GuiaEnquadramento extends CustomPainter {
  const GuiaEnquadramento();

  static const _margem = 10.0;
  static const _tamanhoCanto = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final alturaFoto = size.height * (1 - fracaoFaixaFotoPerfil);
    final esquerda = _margem;
    final direita = size.width - _margem;
    final topo = _margem;
    final base = alturaFoto - _margem;
    final t = _tamanhoCanto;

    final canto = Paint()
      ..color = DalehColors.turf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(esquerda, topo + t), Offset(esquerda, topo), canto);
    canvas.drawLine(Offset(esquerda, topo), Offset(esquerda + t, topo), canto);
    canvas.drawLine(Offset(direita - t, topo), Offset(direita, topo), canto);
    canvas.drawLine(Offset(direita, topo), Offset(direita, topo + t), canto);
    canvas.drawLine(Offset(esquerda, base - t), Offset(esquerda, base), canto);
    canvas.drawLine(Offset(esquerda, base), Offset(esquerda + t, base), canto);
    canvas.drawLine(Offset(direita - t, base), Offset(direita, base), canto);
    canvas.drawLine(Offset(direita, base - t), Offset(direita, base), canto);

    final centroCabeca = Offset(size.width / 2, alturaFoto * 0.4);
    final circulo = Paint()
      ..color = DalehColors.turf.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centroCabeca, size.width * 0.24, circulo);

    final tracejado = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    _tracejada(canvas, Offset(size.width / 2, topo), Offset(size.width / 2, base), tracejado);
    _tracejada(canvas, Offset(esquerda, centroCabeca.dy), Offset(direita, centroCabeca.dy), tracejado);
  }

  void _tracejada(Canvas canvas, Offset inicio, Offset fim, Paint paint) {
    const traco = 6.0;
    const espaco = 5.0;
    final total = (fim - inicio).distance;
    final direcao = (fim - inicio) / total;
    var distancia = 0.0;
    while (distancia < total) {
      final ate = distancia + traco > total ? total : distancia + traco;
      canvas.drawLine(inicio + direcao * distancia, inicio + direcao * ate, paint);
      distancia += traco + espaco;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

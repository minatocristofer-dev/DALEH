import 'package:daleh_app/features/perfil/foto_rosto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rosto já centralizado: sem deslocamento, escala leva a largura do rosto à proporção pedida', () {
    final ajuste = calcularAjusteRosto(
      rosto: const RostoNaFoto(centroX: 0.5, centroY: 0.5, largura: 0.3),
      imagemLargura: 1000,
      imagemAltura: 1000,
      areaLargura: 400,
      areaAltura: 400,
      alvoCentro: const Offset(200, 160),
      larguraAlvoRosto: 0.36,
    );

    expect(ajuste.escala, closeTo(1.2, 1e-9));
    expect(ajuste.offset.dx, closeTo(0, 1e-9));
    expect(ajuste.offset.dy, closeTo(-40, 1e-9));
  });

  test('rosto deslocado para a esquerda: o centro do rosto cai exatamente no alvo depois da transformação', () {
    const rosto = RostoNaFoto(centroX: 0.3, centroY: 0.5, largura: 0.3);
    final ajuste = calcularAjusteRosto(
      rosto: rosto,
      imagemLargura: 1000,
      imagemAltura: 1000,
      areaLargura: 400,
      areaAltura: 400,
      alvoCentro: const Offset(200, 160),
      larguraAlvoRosto: 0.36,
    );

    // Mesma conta que o Transform do widget faz: centro + escala * posição relativa + deslocamento.
    final relX = (rosto.centroX * 1000 - 500) * 0.4;
    final relY = (rosto.centroY * 1000 - 500) * 0.4;
    final posFinalX = 200 + ajuste.escala * relX + ajuste.offset.dx;
    final posFinalY = 200 + ajuste.escala * relY + ajuste.offset.dy;

    expect(posFinalX, closeTo(200, 1e-6));
    expect(posFinalY, closeTo(160, 1e-6));
  });

  test('escala nunca fica abaixo de 1 (a foto sempre cobre a área)', () {
    final ajuste = calcularAjusteRosto(
      rosto: const RostoNaFoto(centroX: 0.5, centroY: 0.5, largura: 0.9),
      imagemLargura: 1000,
      imagemAltura: 1000,
      areaLargura: 400,
      areaAltura: 400,
      alvoCentro: const Offset(200, 160),
      larguraAlvoRosto: 0.36,
    );

    expect(ajuste.escala, 1.0);
  });
}

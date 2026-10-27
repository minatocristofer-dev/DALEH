import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/processamento_foto.dart';

void main() {
  // Card de referência usado em todos os testes: 400x500 (aspecto 0.8, igual
  // ao `aspectoFotoPerfil` real) — os números abaixo foram conferidos à mão
  // a partir das constantes de janela-alvo em `processamento_foto.dart`.
  const cardLargura = 400.0;
  const cardAltura = 500.0;

  test('rosto já centralizado na foto: deslocamento fica perto de zero', () {
    // Foto 1000x1250 (mesmo aspecto do card) com rosto já no centro.
    final r = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(375, 406, 250, 250),
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );

    // A janela fica acima do centro vertical do card (centro em ~31% da
    // altura) — então mesmo com o rosto centralizado na FOTO, o
    // deslocamento vertical não fica em zero: ele sobe o rosto pra dentro
    // da janela. O horizontal, sim, fica perto de zero (janela é
    // centralizada horizontalmente).
    expect(r.offset.dx.abs(), lessThan(5));
    expect(r.offset.dy, lessThan(-10)); // desloca pra cima (negativo)
  });

  test('rosto deslocado pra esquerda na foto: offset puxa pra direita (positivo)', () {
    final r = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(50, 406, 250, 250), // bem à esquerda
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );

    expect(r.offset.dx, greaterThan(0));
  });

  test('rosto deslocado pra direita na foto: offset puxa pra esquerda (negativo)', () {
    final r = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(700, 406, 250, 250), // bem à direita
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );

    expect(r.offset.dx, lessThan(0));
  });

  test('rosto pequeno (pessoa longe) precisa de mais zoom que rosto grande (pessoa perto)', () {
    final rostoPequeno = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(450, 500, 100, 100),
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );
    final rostoGrande = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(350, 400, 300, 300),
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );

    expect(rostoPequeno.escala, greaterThan(rostoGrande.escala));
  });

  test('escala nunca é infinita/NaN mesmo com rosto de altura zero (entrada degenerada)', () {
    final r = calcularEnquadramentoAutomatico(
      fotoLargura: 1000,
      fotoAltura: 1250,
      rosto: const Rect.fromLTWH(500, 625, 0, 0),
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );

    expect(r.escala.isFinite, isTrue);
  });
}

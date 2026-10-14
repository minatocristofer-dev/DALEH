import 'package:flutter/material.dart';

// Forma chanfrada usada tanto no card do jogador quanto na edição da foto —
// a mesma janela, pra o que o jogador enquadra ser exatamente o que aparece no card.
Path caminhoCantoChanfrado(Size size, {required double raio, required double chanfro}) {
  final w = size.width, h = size.height;
  return Path()
    ..moveTo(raio, 0)
    ..lineTo(w - chanfro, 0)
    ..lineTo(w, chanfro)
    ..lineTo(w, h - raio)
    ..quadraticBezierTo(w, h, w - raio, h)
    ..lineTo(raio, h)
    ..quadraticBezierTo(0, h, 0, h - raio)
    ..lineTo(0, raio)
    ..quadraticBezierTo(0, 0, raio, 0)
    ..close();
}

/// Janela da foto do jogador: cantos arredondados e chanfro no canto superior direito.
class ClipFotoJogador extends CustomClipper<Path> {
  const ClipFotoJogador();

  @override
  Path getClip(Size size) => caminhoCantoChanfrado(size, raio: 14, chanfro: 20);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

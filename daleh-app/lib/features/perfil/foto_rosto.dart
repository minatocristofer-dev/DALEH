import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Posição do rosto principal numa foto, em frações da imagem (0 a 1).
class RostoNaFoto {
  final double centroX;
  final double centroY;
  final double largura;

  const RostoNaFoto({required this.centroX, required this.centroY, required this.largura});
}

/// Escala e deslocamento que levam o rosto para o centro da área de
/// enquadramento, com a largura do rosto em proporção fixa da área.
class AjusteFoto {
  final double escala;
  final Offset offset;

  const AjusteFoto({required this.escala, required this.offset});
}

/// Detecta o rosto mais evidente na foto, no próprio aparelho. Devolve nulo
/// quando não encontra nenhum rosto — nesse caso o ajuste fica manual.
Future<RostoNaFoto?> detectarRostoNaFoto(String caminhoArquivo, {required double largura, required double altura}) async {
  final detector = FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate));
  try {
    final rostos = await detector.processImage(InputImage.fromFilePath(caminhoArquivo));
    if (rostos.isEmpty) return null;
    final maior = rostos.reduce((a, b) => a.boundingBox.width >= b.boundingBox.width ? a : b);
    final caixa = maior.boundingBox;
    return RostoNaFoto(
      centroX: caixa.center.dx / largura,
      centroY: caixa.center.dy / altura,
      largura: caixa.width / largura,
    );
  } finally {
    await detector.close();
  }
}

/// Calcula como posicionar a foto (com `BoxFit.cover` dentro da área) para
/// que o rosto fique centralizado em `alvoCentro` e ocupe `larguraAlvoRosto`
/// da largura da área. `areaLargura`/`areaAltura` são o tamanho da área da
/// foto, sem a faixa de nome.
AjusteFoto calcularAjusteRosto({
  required RostoNaFoto rosto,
  required double imagemLargura,
  required double imagemAltura,
  required double areaLargura,
  required double areaAltura,
  required Offset alvoCentro,
  required double larguraAlvoRosto,
}) {
  final cobrir = (areaLargura / imagemLargura) > (areaAltura / imagemAltura)
      ? areaLargura / imagemLargura
      : areaAltura / imagemAltura;

  final centroRelX = (rosto.centroX * imagemLargura - imagemLargura / 2) * cobrir;
  final centroRelY = (rosto.centroY * imagemAltura - imagemAltura / 2) * cobrir;
  final larguraRostoNaTela = rosto.largura * imagemLargura * cobrir;

  var escala = larguraAlvoRosto * areaLargura / larguraRostoNaTela;
  escala = escala < 1.0 ? 1.0 : (escala > 4.0 ? 4.0 : escala);

  final centroAreaX = areaLargura / 2;
  final centroAreaY = areaAltura / 2;
  final offset = Offset(
    alvoCentro.dx - centroAreaX - escala * centroRelX,
    alvoCentro.dy - centroAreaY - escala * centroRelY,
  );
  return AjusteFoto(escala: escala, offset: offset);
}

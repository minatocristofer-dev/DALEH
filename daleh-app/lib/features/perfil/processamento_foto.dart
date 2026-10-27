import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

/// Posição-alvo da cabeça dentro do card inteiro (frações do card, mesmo
/// aspecto de `aspectoFotoPerfil`) — ponto de referência usado pelo
/// enquadramento automático.
const _cabecaCentroX = 0.5;
const _cabecaCentroY = 0.345;
const _cabecaAltura = 0.40;

// Quanto da altura-alvo o rosto DETECTADO (ML Kit — só sobrancelha até
// queixo, não inclui cabelo) deve ocupar. Propositalmente bem menor que
// 1.0: o bounding box do rosto não inclui o cabelo, então sobra margem
// acima pra cabelos volumosos não serem cortados no topo do card.
const _fracaoRostoNaJanela = 0.575;

/// Resultado de detectar rosto(s) numa foto.
class ResultadoDeteccaoRosto {
  final int quantidadeRostos;
  final Rect? rosto; // bounding box em pixels da foto original; só quando quantidadeRostos == 1
  const ResultadoDeteccaoRosto({required this.quantidadeRostos, this.rosto});
}

/// Abstração pra permitir um detector falso nos testes (ML Kit usa canal de
/// plataforma nativo, não roda em `flutter_test`).
abstract class DetectorDeRosto {
  Future<ResultadoDeteccaoRosto> detectar(String caminhoArquivo);
  void dispose();
}

class DetectorDeRostoMlKit implements DetectorDeRosto {
  final _detector = FaceDetector(options: FaceDetectorOptions());

  @override
  Future<ResultadoDeteccaoRosto> detectar(String caminhoArquivo) async {
    final rostos = await _detector.processImage(InputImage.fromFilePath(caminhoArquivo));
    if (rostos.length != 1) return ResultadoDeteccaoRosto(quantidadeRostos: rostos.length);
    return ResultadoDeteccaoRosto(quantidadeRostos: 1, rosto: rostos.first.boundingBox);
  }

  @override
  void dispose() => _detector.close();
}

final detectorDeRostoProvider = Provider<DetectorDeRosto>((ref) {
  final detector = DetectorDeRostoMlKit();
  ref.onDispose(detector.dispose);
  return detector;
});

/// Máscara de segmentação de pessoa: uma confiança (0.0 a 1.0, pessoa vs.
/// fundo) por pixel, alinhada à resolução da própria foto original.
class MascaraDeSegmentacao {
  final int largura;
  final int altura;
  final List<double> confidencias;
  const MascaraDeSegmentacao({required this.largura, required this.altura, required this.confidencias});
}

/// Abstração pra permitir um segmentador falso nos testes.
abstract class SegmentadorDePessoa {
  Future<MascaraDeSegmentacao?> segmentar(String caminhoArquivo);
  void dispose();
}

class SegmentadorDePessoaMlKit implements SegmentadorDePessoa {
  final _segmentador = SelfieSegmenter(mode: SegmenterMode.single, enableRawSizeMask: false);

  @override
  Future<MascaraDeSegmentacao?> segmentar(String caminhoArquivo) async {
    final mascara = await _segmentador.processImage(InputImage.fromFilePath(caminhoArquivo));
    if (mascara == null) return null;
    return MascaraDeSegmentacao(largura: mascara.width, altura: mascara.height, confidencias: mascara.confidences);
  }

  @override
  void dispose() => _segmentador.close();
}

final segmentadorDePessoaProvider = Provider<SegmentadorDePessoa>((ref) {
  final segmentador = SegmentadorDePessoaMlKit();
  ref.onDispose(segmentador.dispose);
  return segmentador;
});

/// Aplica a máscara de segmentação como canal alpha da imagem original —
/// onde a confiança é baixa (fundo), o pixel vira transparente; onde é alta
/// (pessoa: cabeça, cabelo, rosto, ombros, roupa), o pixel original é
/// mantido. Função pura sobre pixels (sem I/O), testável com qualquer
/// entrada — nunca lança (se a máscara não bater com a imagem, devolve a
/// imagem original sem alterar).
Future<ui.Image> aplicarMascaraDeFundo({
  required ui.Image original,
  required MascaraDeSegmentacao mascara,
}) async {
  final byteData = await original.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null || mascara.largura <= 0 || mascara.altura <= 0) return original;

  final largura = original.width;
  final altura = original.height;
  final pixels = Uint8List.fromList(byteData.buffer.asUint8List());

  for (var y = 0; y < altura; y++) {
    final my = (y * mascara.altura / altura).floor().clamp(0, mascara.altura - 1);
    for (var x = 0; x < largura; x++) {
      final mx = (x * mascara.largura / largura).floor().clamp(0, mascara.largura - 1);
      final confianca = mascara.confidencias[my * mascara.largura + mx];
      final pixelIdx = (y * largura + x) * 4;
      final alphaAtual = pixels[pixelIdx + 3];
      pixels[pixelIdx + 3] = (alphaAtual * confianca).round().clamp(0, 255);
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(pixels, largura, altura, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

/// Enquadramento calculado pra uma foto: escala e deslocamento a aplicar
/// nos mesmos `_escala`/`_offset` que o ajuste manual (arrastar/pinçar) já
/// usa — o automático só escolhe um ponto de partida melhor, o jogador
/// sempre pode continuar ajustando por cima.
class EnquadramentoAutomatico {
  final double escala;
  final Offset offset;
  const EnquadramentoAutomatico({required this.escala, required this.offset});
}

/// Calcula o enquadramento automático a partir do bounding box do rosto
/// (em pixels da foto original) de forma que o rosto fique centralizado e
/// com tamanho consistente dentro do card. Função pura (sem I/O), testável
/// com qualquer número — sem precisar de imagem de verdade nem de detector.
EnquadramentoAutomatico calcularEnquadramentoAutomatico({
  required int fotoLargura,
  required int fotoAltura,
  required Rect rosto,
  required double cardLargura,
  required double cardAltura,
}) {
  final coverScale = cardLargura / fotoLargura > cardAltura / fotoAltura
      ? cardLargura / fotoLargura
      : cardAltura / fotoAltura;
  final dispLargura = fotoLargura * coverScale;
  final dispAltura = fotoAltura * coverScale;

  final rostoCentroXTela = (cardLargura - dispLargura) / 2 + rosto.center.dx * coverScale;
  final rostoCentroYTela = (cardAltura - dispAltura) / 2 + rosto.center.dy * coverScale;

  final alturaRostoTela = rosto.height * coverScale;
  final alturaAlvoNaTela = cardAltura * _cabecaAltura * _fracaoRostoNaJanela;
  final escala = alturaRostoTela <= 0 ? 1.0 : alturaAlvoNaTela / alturaRostoTela;

  final cabecaCentroXTela = cardLargura * _cabecaCentroX;
  final cabecaCentroYTela = cardAltura * _cabecaCentroY;

  final dx = cabecaCentroXTela - cardLargura / 2 - escala * (rostoCentroXTela - cardLargura / 2);
  final dy = cabecaCentroYTela - cardAltura / 2 - escala * (rostoCentroYTela - cardAltura / 2);

  return EnquadramentoAutomatico(escala: escala, offset: Offset(dx, dy));
}

/// Resultado de processar uma foto recém-escolhida: a imagem já sem fundo
/// (ou a original, se a segmentação não estiver disponível) e, quando um
/// rosto foi encontrado, o enquadramento automático pronto pra usar. Nunca
/// um erro fatal — o jogador sempre pode ajustar manualmente por cima.
class ResultadoProcessamentoFoto {
  final Uint8List? fotoProcessadaPng;
  final EnquadramentoAutomatico? enquadramento;
  final String? mensagem;
  const ResultadoProcessamentoFoto({this.fotoProcessadaPng, this.enquadramento, this.mensagem});
}

const mensagemFalhaDeteccao =
    'Não conseguimos centralizar o rosto automaticamente. Tente outra imagem com o rosto visível e enquadramento do peito pra cima, ou posicione manualmente.';

const mensagemFalhaLeitura = 'Não conseguimos abrir essa imagem. Tente escolher outra foto.';

/// Decodifica a foto, remove o fundo (segmentação) e detecta o rosto
/// principal pra calcular o enquadramento automático. Nunca lança —
/// qualquer falha (foto ilegível, segmentação ou detecção indisponível)
/// degrada graciosamente, nunca derruba o app.
Future<ResultadoProcessamentoFoto> processarFotoEscolhida({
  required String caminhoArquivo,
  required Uint8List bytes,
  required DetectorDeRosto detector,
  required SegmentadorDePessoa segmentador,
  required double cardLargura,
  required double cardAltura,
}) async {
  final ui.Image original;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    original = frame.image;
  } catch (_) {
    return const ResultadoProcessamentoFoto(mensagem: mensagemFalhaLeitura);
  }

  var imagemProcessada = original;
  try {
    // Timeout defensivo: o ML Kit pode baixar o modelo de segmentação via
    // Google Play Services na primeira vez que roda num aparelho — numa
    // rede ruim isso pode travar o canal de plataforma indefinidamente em
    // vez de lançar um erro (achado possível em QA real num aparelho
    // físico, nunca visto no emulador, que já tem o modelo pronto).
    final mascara = await segmentador.segmentar(caminhoArquivo).timeout(const Duration(seconds: 20));
    if (mascara != null) {
      imagemProcessada = await aplicarMascaraDeFundo(original: original, mascara: mascara);
    }
  } catch (_) {
    // Segmentação indisponível/falhou/travou — segue com a foto original
    // (sem remover fundo), nunca trava o fluxo por causa disso.
  }

  // Volta pra PNG já aqui (em vez de entregar o `ui.Image` direto pro
  // widget) — o `ui.Image` com canal alpha modificado via
  // `decodeImageFromPixels` não é exibido corretamente pelo `RawImage` no
  // backend de renderização Impeller (alpha ignorado ao vivo, mesmo
  // codificando certo); um PNG de verdade, mostrado via `Image.memory`,
  // passa pelo decodificador de imagem padrão e funciona.
  final pngBytes = await imagemProcessada.toByteData(format: ui.ImageByteFormat.png);
  final fotoProcessadaPng = pngBytes?.buffer.asUint8List();

  try {
    final resultado = await detector.detectar(caminhoArquivo).timeout(const Duration(seconds: 20));
    if (resultado.quantidadeRostos != 1 || resultado.rosto == null) {
      return ResultadoProcessamentoFoto(fotoProcessadaPng: fotoProcessadaPng, mensagem: mensagemFalhaDeteccao);
    }
    final enquadramento = calcularEnquadramentoAutomatico(
      fotoLargura: original.width,
      fotoAltura: original.height,
      rosto: resultado.rosto!,
      cardLargura: cardLargura,
      cardAltura: cardAltura,
    );
    return ResultadoProcessamentoFoto(fotoProcessadaPng: fotoProcessadaPng, enquadramento: enquadramento);
  } catch (_) {
    return ResultadoProcessamentoFoto(fotoProcessadaPng: fotoProcessadaPng, mensagem: mensagemFalhaDeteccao);
  }
}

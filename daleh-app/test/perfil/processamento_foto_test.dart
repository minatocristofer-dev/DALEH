import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/processamento_foto.dart';

class _DetectorFalso implements DetectorDeRosto {
  final ResultadoDeteccaoRosto resultado;
  _DetectorFalso(this.resultado);

  @override
  Future<ResultadoDeteccaoRosto> detectar(String caminhoArquivo) async => resultado;

  @override
  void dispose() {}
}

class _SegmentadorFalso implements SegmentadorDePessoa {
  final MascaraDeSegmentacao? mascara;
  final bool lancarErro;
  _SegmentadorFalso({this.mascara, this.lancarErro = false});

  @override
  Future<MascaraDeSegmentacao?> segmentar(String caminhoArquivo) async {
    if (lancarErro) throw Exception('segmentador indisponível');
    return mascara;
  }

  @override
  void dispose() {}
}

/// Gera um PNG mínimo (100x125, aspecto igual ao card) só pra ter bytes
/// decodificáveis de verdade — o conteúdo visual não importa, detector e
/// segmentador são sempre falsos nesses testes.
Future<Uint8List> _fotoDeTeste() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 125), Paint()..color = const Color(0xFF888888));
  final imagem = await recorder.endRecording().toImage(100, 125);
  final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

MascaraDeSegmentacao _mascaraMetadePessoa(int largura, int altura) {
  // Metade de cima (cabeça/ombros) = pessoa (confiança 1.0), metade de
  // baixo = fundo (confiança 0.0) — simples o bastante pra verificar que a
  // máscara é aplicada de verdade, sem precisar de uma foto real.
  final confidencias = List<double>.generate(largura * altura, (i) => i < (largura * altura) / 2 ? 1.0 : 0.0);
  return MascaraDeSegmentacao(largura: largura, altura: altura, confidencias: confidencias);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('processarFotoEscolhida', () {
    test('um rosto detectado e segmentação ok: devolve imagem processada e enquadramento, sem mensagem', () async {
      final bytes = await _fotoDeTeste();
      final detector = _DetectorFalso(const ResultadoDeteccaoRosto(quantidadeRostos: 1, rosto: Rect.fromLTWH(30, 30, 40, 40)));
      final segmentador = _SegmentadorFalso(mascara: _mascaraMetadePessoa(100, 125));

      final r = await processarFotoEscolhida(
        caminhoArquivo: '/tmp/foto.png',
        bytes: bytes,
        detector: detector,
        segmentador: segmentador,
        cardLargura: 400,
        cardAltura: 500,
      );

      expect(r.mensagem, isNull);
      expect(r.fotoProcessadaPng, isNotNull);
      expect(r.enquadramento, isNotNull);
      expect(r.enquadramento!.escala.isFinite, isTrue);
    });

    test('nenhum rosto detectado: ainda devolve a imagem processada, com mensagem de fallback', () async {
      final bytes = await _fotoDeTeste();
      final detector = _DetectorFalso(const ResultadoDeteccaoRosto(quantidadeRostos: 0));
      final segmentador = _SegmentadorFalso(mascara: _mascaraMetadePessoa(100, 125));

      final r = await processarFotoEscolhida(
        caminhoArquivo: '/tmp/foto.png',
        bytes: bytes,
        detector: detector,
        segmentador: segmentador,
        cardLargura: 400,
        cardAltura: 500,
      );

      expect(r.mensagem, mensagemFalhaDeteccao);
      expect(r.fotoProcessadaPng, isNotNull); // fundo já removido, só falta o auto-enquadramento
      expect(r.enquadramento, isNull);
    });

    test('mais de um rosto detectado: mesma mensagem de fallback (não escolhe um sozinho)', () async {
      final bytes = await _fotoDeTeste();
      final detector = _DetectorFalso(const ResultadoDeteccaoRosto(quantidadeRostos: 2));
      final segmentador = _SegmentadorFalso(mascara: _mascaraMetadePessoa(100, 125));

      final r = await processarFotoEscolhida(
        caminhoArquivo: '/tmp/foto.png',
        bytes: bytes,
        detector: detector,
        segmentador: segmentador,
        cardLargura: 400,
        cardAltura: 500,
      );

      expect(r.mensagem, mensagemFalhaDeteccao);
      expect(r.enquadramento, isNull);
    });

    test('segmentador indisponível/falha: segue com a foto original, sem crashar', () async {
      final bytes = await _fotoDeTeste();
      final detector = _DetectorFalso(const ResultadoDeteccaoRosto(quantidadeRostos: 1, rosto: Rect.fromLTWH(10, 10, 20, 20)));
      final segmentador = _SegmentadorFalso(lancarErro: true);

      final r = await processarFotoEscolhida(
        caminhoArquivo: '/tmp/foto.png',
        bytes: bytes,
        detector: detector,
        segmentador: segmentador,
        cardLargura: 400,
        cardAltura: 500,
      );

      expect(r.mensagem, isNull);
      expect(r.fotoProcessadaPng, isNotNull);
      expect(r.enquadramento, isNotNull);
    });

    test('foto corrompida/ilegível: nunca lança, devolve mensagem e nenhuma imagem', () async {
      final detector = _DetectorFalso(const ResultadoDeteccaoRosto(quantidadeRostos: 1, rosto: Rect.fromLTWH(0, 0, 10, 10)));
      final segmentador = _SegmentadorFalso(mascara: null);

      final r = await processarFotoEscolhida(
        caminhoArquivo: '/tmp/foto.png',
        bytes: Uint8List.fromList([1, 2, 3, 4]), // não é um PNG válido
        detector: detector,
        segmentador: segmentador,
        cardLargura: 400,
        cardAltura: 500,
      );

      expect(r.mensagem, mensagemFalhaLeitura);
      expect(r.fotoProcessadaPng, isNull);
      expect(r.enquadramento, isNull);
    });
  });

  group('aplicarMascaraDeFundo', () {
    test('pixel marcado como fundo (confiança 0) vira transparente', () async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint()..color = const Color(0xFFFFFFFF));
      final original = await recorder.endRecording().toImage(4, 4);

      // Metade de cima = pessoa (1.0), metade de baixo = fundo (0.0).
      final confidencias = List<double>.generate(16, (i) => i < 8 ? 1.0 : 0.0);
      final mascara = MascaraDeSegmentacao(largura: 4, altura: 4, confidencias: confidencias);

      final resultado = await aplicarMascaraDeFundo(original: original, mascara: mascara);
      final bytes = await resultado.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = bytes!.buffer.asUint8List();

      // Pixel (0,0): linha 0 -> pessoa -> alpha deve continuar opaco (255).
      expect(pixels[3], 255);
      // Pixel (0,3): linha 3 (última) -> fundo -> alpha deve ir a zero.
      final idxUltimaLinha = (3 * 4 + 0) * 4;
      expect(pixels[idxUltimaLinha + 3], 0);
    });

    test('máscara com dimensão inválida (zero): devolve a imagem original sem alterar', () async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 2, 2), Paint()..color = const Color(0xFFFFFFFF));
      final original = await recorder.endRecording().toImage(2, 2);

      final mascara = const MascaraDeSegmentacao(largura: 0, altura: 0, confidencias: []);
      final resultado = await aplicarMascaraDeFundo(original: original, mascara: mascara);

      expect(resultado, same(original));
    });
  });
}

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/daleh_theme.dart';
import 'editar_foto_controller.dart';
import 'foto_perfil_layout.dart';

// Um template só (ver decisão do usuário — nada de escolher pose por
// enquanto). Escudo/logo do time no peito fica pra uma fase futura: precisa
// de um campo novo pra upload do escudo do time, que ainda não existe.
const _templateAsset = 'assets/jerseys/jersey_solto.png';

// Recorte oval do rosto — sem remoção de fundo (decisão do usuário em QA:
// segmentação de pessoa via IA é feature grande demais pra agora, fica pra
// depois). Proporção em relação à altura/largura do quadro — como o quadro
// já não é quadrado (aspectoFotoPerfil), largura/altura iguais aqui NÃO dão
// um oval igual nos dois eixos; os valores abaixo foram escolhidos pra dar
// uma proporção final de rosto (mais alto que largo), não um círculo.
const _larguraOval = 0.5;
const _alturaOval = 0.56;

// Quanto o oval "afunda" atrás do colarinho da camisa — em FRAÇÃO da altura
// do quadro, não em pixels fixos. Testado no emulador com pixels fixos
// (22px) e funcionou lá, mas num celular real com outra densidade/tamanho
// de tela a mesma folga em pixels vira uma fresta visível de novo (QA
// 2026-09-21) — fração escala igual em qualquer tela.
const _sobreposicaoOvalCamisa = 0.035;

/// Deixa o jogador tirar/escolher uma foto e posicioná-la (arrastar +
/// pinçar) dentro de um recorte oval — o resto do quadro é fundo sólido, sem
/// mostrar nada da foto original além do que cai dentro do oval. A camisa
/// do DALEH fica como uma faixa fixa na base, ocupando no máximo 1/3 da
/// altura (pedido explícito do usuário em QA). O resultado é achatado num
/// único PNG (mesma técnica de `player_card_share.dart`) e enviado pro
/// backend.
class EditarFotoScreen extends ConsumerStatefulWidget {
  const EditarFotoScreen({super.key});

  @override
  ConsumerState<EditarFotoScreen> createState() => _EditarFotoScreenState();
}

class _EditarFotoScreenState extends ConsumerState<EditarFotoScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  Uint8List? _foto;
  Offset _offset = Offset.zero;
  double _escala = 1.0;
  double _escalaBase = 1.0;
  String? _erro;

  Future<void> _escolherFoto(ImageSource origem) async {
    final arquivo = await _picker.pickImage(source: origem, imageQuality: 90);
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    setState(() {
      _foto = bytes;
      _offset = Offset.zero;
      _escala = 1.0;
      _erro = null;
    });
  }

  Future<void> _salvar() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    final imagem = await boundary.toImage(pixelRatio: 3);
    final bytesPng = await imagem.toByteData(format: ui.ImageByteFormat.png);
    if (bytesPng == null) return;

    final erro = await ref.read(editarFotoControllerProvider.notifier).enviarAvatar(bytesPng.buffer.asUint8List());
    if (!mounted) return;
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(editarFotoControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Foto de perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Arraste pra posicionar e pinça pra ajustar o tamanho do seu rosto dentro do oval — a camisa fica fixa como uma faixa na base.',
            style: TextStyle(color: DalehColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(child: _canvas()),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeria'),
                ),
              ),
            ],
          ),
          if (_erro != null) ...[
            const SizedBox(height: 16),
            Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _foto == null || estado.enviando ? null : _salvar,
            child: estado.enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.bg),
                  )
                : const Text('Salvar foto de perfil'),
          ),
        ],
      ),
    );
  }

  Widget _canvas() {
    return AspectRatio(
      aspectRatio: aspectoFotoPerfil,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DalehRadius.lg),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: DalehColors.line), color: DalehColors.surface2),
            // `LayoutBuilder` porque o encaixe do oval com o colarinho da
            // camisa precisa de uma sobreposição em PIXELS reais (não em
            // fração/alinhamento) — só assim dá pra garantir uma folga
            // negativa fixa (o queixo "afunda" atrás do colarinho) que não
            // depende de arredondamento de porcentagem.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final altura = constraints.maxHeight;
                final largura = constraints.maxWidth;
                final alturaCamisa = altura * fracaoCamisaFotoPerfil;
                final alturaOval = altura * _alturaOval;
                final larguraOval = largura * _larguraOval;
                // O oval desce até ficar por trás do colarinho, não só
                // encostado nele — sem isso sobra uma fresta de fundo sólido
                // entre o queixo e a camisa.
                final baseOval = alturaCamisa - (altura * _sobreposicaoOvalCamisa);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: (largura - larguraOval) / 2,
                      width: larguraOval,
                      height: alturaOval,
                      bottom: baseOval,
                      // Rosto num recorte OVAL de verdade (mais alto que
                      // largo, como um rosto) — `BoxShape.circle`/
                      // `CircleBorder` sempre desenham um círculo perfeito
                      // usando o lado menor da caixa, ignorando a proporção
                      // real, então a borda é desenhada à parte com
                      // `CustomPaint`/`drawOval`, que respeita a caixa
                      // não-quadrada. Fora do oval é só o fundo sólido do
                      // `Container` acima, nunca mostra o resto da foto.
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Sombra suave por trás do rosto — dá uma
                          // sensação de profundidade/acabamento sem
                          // desenhar um contorno vistoso em cima de um
                          // rosto de verdade (um anel lima brilhante em
                          // volta do rosto ficava com cara de figurinha,
                          // não de foto — feedback direto do usuário em
                          // QA, 2026-09-21).
                          const IgnorePointer(child: CustomPaint(painter: _SombraOval())),
                          ClipOval(
                            child: _foto == null
                                ? const Icon(Icons.person_outline, size: 48, color: DalehColors.muted)
                                : GestureDetector(
                                    onScaleStart: (_) => _escalaBase = _escala,
                                    onScaleUpdate: (d) {
                                      setState(() {
                                        // `num.clamp` devolve `num`, não
                                        // `double` — por isso o clamp manual
                                        // em vez de `.clamp(0.3, 4.0)` direto.
                                        final novaEscala = _escalaBase * d.scale;
                                        _escala = novaEscala < 0.3 ? 0.3 : (novaEscala > 4.0 ? 4.0 : novaEscala);
                                        _offset += d.focalPointDelta;
                                      });
                                    },
                                    child: ClipRect(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..translate(_offset.dx, _offset.dy)
                                          ..scale(_escala),
                                        child: Image.memory(
                                          _foto!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Camisa como faixa fixa na base (no máximo 1/3 da
                    // altura) — desenhada DEPOIS do oval no Stack, então
                    // cobre a ponta do queixo que "afunda" atrás dela.
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        height: alturaCamisa,
                        width: largura,
                        child: IgnorePointer(child: Image.asset(_templateAsset, fit: BoxFit.cover)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Sombra suave atrás do oval — só uma pista discreta de profundidade
// (o rosto "assenta" no quadro em vez de flutuar), nunca um contorno
// chamativo. `drawOval` (não `CircleBorder`/`BoxShape.circle`, que sempre
// desenham um círculo perfeito) porque a caixa é propositalmente não
// quadrada.
class _SombraOval extends CustomPainter {
  const _SombraOval();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final area = Rect.fromLTWH(-4, -2, size.width + 8, size.height + 10);
    canvas.drawOval(area, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

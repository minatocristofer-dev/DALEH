import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/daleh_theme.dart';
import 'editar_foto_controller.dart';
import 'foto_perfil_layout.dart';
import 'foto_rosto.dart';
import 'guia_enquadramento.dart';

/// Monta o card padronizado da foto de perfil a partir de uma foto real
/// escolhida pelo jogador: foto enquadrada (arrastar + pinçar dentro da área
/// guia) e uma faixa inferior com nome e posição. Nada é gerado por IA: é só
/// recorte e composição sobre a foto original. O resultado é achatado num PNG
/// e enviado pro backend como `avatarUrl`.
class EditarFotoScreen extends ConsumerStatefulWidget {
  final String nome;
  final String? posicao;

  const EditarFotoScreen({super.key, required this.nome, this.posicao});

  @override
  ConsumerState<EditarFotoScreen> createState() => _EditarFotoScreenState();
}

class _EditarFotoScreenState extends ConsumerState<EditarFotoScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  Uint8List? _foto;
  RostoNaFoto? _rosto;
  Size? _dimensoesFoto;
  bool _precisaCentralizar = false;
  Offset _offset = Offset.zero;
  double _escala = 1.0;
  double _escalaBase = 1.0;
  String? _erro;

  Future<void> _escolherFoto(ImageSource origem) async {
    final arquivo = await _picker.pickImage(source: origem, imageQuality: 90);
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();

    final codec = await ui.instantiateImageCodec(bytes);
    final quadro = await codec.getNextFrame();
    final dimensoes = Size(quadro.image.width.toDouble(), quadro.image.height.toDouble());
    quadro.image.dispose();

    RostoNaFoto? rosto;
    try {
      rosto = await detectarRostoNaFoto(arquivo.path, largura: dimensoes.width, altura: dimensoes.height);
    } catch (_) {
      rosto = null;
    }
    if (!mounted) return;

    setState(() {
      _foto = bytes;
      _offset = Offset.zero;
      _escala = 1.0;
      _erro = null;
      _rosto = rosto;
      _dimensoesFoto = dimensoes;
      _precisaCentralizar = rosto != null;
    });
    if (rosto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não encontrei um rosto nessa foto. Ajuste manualmente.')),
      );
    }
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
            'Arraste a foto pra posicionar o rosto no card e pinça pra ajustar o tamanho. O nome e a posição entram automaticamente na faixa de baixo.',
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
    return GestureDetector(
      onScaleStart: _foto == null ? null : (_) => _escalaBase = _escala,
      onScaleUpdate: _foto == null
          ? null
          : (d) {
              setState(() {
                final nova = _escalaBase * d.scale;
                _escala = nova < 1.0 ? 1.0 : (nova > 4.0 ? 4.0 : nova);
                _offset += d.focalPointDelta;
              });
            },
      child: AspectRatio(
        aspectRatio: aspectoFotoPerfil,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(key: _boundaryKey, child: _cardFoto()),
            IgnorePointer(child: CustomPaint(painter: GuiaEnquadramento())),
          ],
        ),
      ),
    );
  }

  Widget _cardFoto() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DalehRadius.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final altura = constraints.maxHeight;
          final alturaFaixa = altura * fracaoFaixaFotoPerfil;
          final alturaFoto = altura - alturaFaixa;
          final largura = constraints.maxWidth;
          if (_precisaCentralizar && _rosto != null && _dimensoesFoto != null) {
            final ajuste = calcularAjusteRosto(
              rosto: _rosto!,
              imagemLargura: _dimensoesFoto!.width,
              imagemAltura: _dimensoesFoto!.height,
              areaLargura: largura,
              areaAltura: alturaFoto,
              alvoCentro: Offset(largura / 2, alturaFoto * 0.4),
              larguraAlvoRosto: 0.36,
            );
            _escala = ajuste.escala;
            _offset = ajuste.offset;
            _precisaCentralizar = false;
          }
          final maxDx = (_escala - 1) * largura / 2;
          final maxDy = (_escala - 1) * alturaFoto / 2;
          final dx = _offset.dx > maxDx ? maxDx : (_offset.dx < -maxDx ? -maxDx : _offset.dx);
          final dy = _offset.dy > maxDy ? maxDy : (_offset.dy < -maxDy ? -maxDy : _offset.dy);
          return Container(
            color: DalehColors.bg,
            child: Column(
              children: [
                Expanded(
                  child: ClipRect(
                    child: _foto == null
                        ? const Center(child: Icon(Icons.person_outline, size: 64, color: DalehColors.muted))
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translate(dx, dy)
                              ..scale(_escala),
                            child: Image.memory(_foto!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          ),
                  ),
                ),
                SizedBox(
                  height: alturaFaixa,
                  width: double.infinity,
                  child: _faixaNome(alturaFaixa),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _faixaNome(double altura) {
    final posicao = widget.posicao;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: altura * 0.12),
      decoration: const BoxDecoration(
        color: DalehColors.bg,
        border: Border(top: BorderSide(color: DalehColors.turf, width: 2)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.nome.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: DalehColors.text),
            ),
          ),
          if (posicao != null && posicao.isNotEmpty) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                posicao.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.5, color: DalehColors.turf),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


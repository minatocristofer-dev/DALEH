import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/daleh_theme.dart';
import 'editar_foto_controller.dart';

// Um template só (ver decisão do usuário — nada de escolher pose por
// enquanto). Escudo/logo do time no peito fica pra uma fase futura: precisa
// de um campo novo pra upload do escudo do time, que ainda não existe.
const _templateAsset = 'assets/jerseys/jersey_solto.png';

// Proporção real do template (1086x1448) — mantém o encaixe da foto
// consistente com o corte de pescoço da pose.
const _aspectoTemplate = 1086 / 1448;

/// Deixa o jogador tirar/escolher uma foto e posicioná-la (arrastar +
/// pinçar) por trás do template da camisa do DALEH — a área transparente do
/// PNG (rosto/pescoço) deixa a foto aparecer, a área opaca (camisa/torso)
/// cobre o resto. O resultado é achatado num único PNG (mesma técnica de
/// `player_card_share.dart`) e enviado pro backend.
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
            'Encaixe sua foto na camisa do DALEH: arraste pra posicionar, pinça pra ajustar o tamanho.',
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
      aspectRatio: _aspectoTemplate,
      child: RepaintBoundary(
        key: _boundaryKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DalehRadius.lg),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: DalehColors.line), color: DalehColors.surface2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_foto == null)
                  const Center(
                    child: Icon(Icons.person_outline, size: 64, color: DalehColors.muted),
                  )
                else
                  GestureDetector(
                    onScaleStart: (_) => _escalaBase = _escala,
                    onScaleUpdate: (d) {
                      setState(() {
                        // `num.clamp` devolve `num`, não `double` — por isso
                        // o clamp manual em vez de `.clamp(0.3, 4.0)` direto.
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
                        child: Image.memory(_foto!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                    ),
                  ),
                IgnorePointer(child: Image.asset(_templateAsset, fit: BoxFit.cover)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

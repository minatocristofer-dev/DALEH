import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/daleh_theme.dart';
import 'editar_foto_controller.dart';
import 'foto_perfil_layout.dart';
import 'processamento_foto.dart';
import 'widgets/moldura_foto.dart';

/// Monta automaticamente o card padronizado da foto de perfil a partir de
/// uma foto real escolhida pelo jogador: detecta o rosto, remove o fundo
/// (segmentação no aparelho) e centraliza cabelo/rosto/ombros/roupa reais
/// dentro do card padrão do DALEH. Nada é gerado por IA: é remoção de fundo
/// + enquadramento automático. Antes de escolher a foto, não existe nenhum
/// crop/silhueta pra mostrar — só depois que a composição automática é
/// gerada é que o preview aparece, já pronto (ajuste manual só reposiciona
/// por cima disso). O resultado é achatado num PNG e enviado pro backend
/// como `avatarUrl`.
class EditarFotoScreen extends ConsumerStatefulWidget {
  const EditarFotoScreen({super.key});

  @override
  ConsumerState<EditarFotoScreen> createState() => _EditarFotoScreenState();
}

class _EditarFotoScreenState extends ConsumerState<EditarFotoScreen> {
  final _boundaryKey = GlobalKey();
  final _picker = ImagePicker();

  Uint8List? _fotoProcessadaPng;
  EnquadramentoAutomatico? _enquadramentoAutomatico;
  Offset _offset = Offset.zero;
  double _escala = 1.0;
  double _escalaBase = 1.0;
  String? _erro;
  String? _avisoAjusteAutomatico;
  bool _ajustando = false;

  Future<void> _escolherFoto(ImageSource origem) async {
    final XFile? arquivo;
    try {
      // `maxWidth`/`maxHeight` redimensionam a foto ainda dentro do picker,
      // antes de qualquer processamento — sem isso, uma foto tirada na hora
      // pela câmera (facilmente 4000x3000+ num aparelho real, bem maior que
      // a média das fotos de galeria) faz o processamento pixel a pixel da
      // segmentação alocar dezenas de MB em múltiplos buffers e derruba o
      // app por falta de memória.
      arquivo = await _picker.pickImage(
        source: origem,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (e) {
      // Câmera/galeria pode falhar por permissão negada, app de câmera
      // ausente, etc. — sem esse catch, qualquer uma dessas situações
      // derrubava o fluxo em silêncio (achado em QA real num aparelho
      // físico; nunca reproduzido no emulador, que concede permissão sem
      // perguntar).
      if (!mounted) return;
      setState(() {
        _erro = origem == ImageSource.camera
            ? 'Não foi possível abrir a câmera. Verifique se o DALEH tem permissão de câmera nas configurações do aparelho.'
            : 'Não foi possível abrir a galeria. Verifique as permissões do DALEH nas configurações do aparelho.';
      });
      return;
    }
    if (arquivo == null) return;

    setState(() {
      _erro = null;
      _avisoAjusteAutomatico = null;
      _ajustando = true;
    });

    try {
      final bytes = await arquivo.readAsBytes();
      // Remove o fundo (segmentação) e calcula o enquadramento automático do
      // rosto — o jogador sempre pode arrastar/pinçar por cima depois, com ou
      // sem sucesso nesses dois passos.
      final larguraCard = MediaQuery.sizeOf(context).width - 40;
      final alturaCard = larguraCard / aspectoFotoPerfil;
      final resultado = await processarFotoEscolhida(
        caminhoArquivo: arquivo.path,
        bytes: bytes,
        detector: ref.read(detectorDeRostoProvider),
        segmentador: ref.read(segmentadorDePessoaProvider),
        cardLargura: larguraCard,
        cardAltura: alturaCard,
      );
      if (!mounted) return;
      setState(() {
        _ajustando = false;
        _fotoProcessadaPng = resultado.fotoProcessadaPng;
        _avisoAjusteAutomatico = resultado.mensagem;
        _enquadramentoAutomatico = resultado.enquadramento;
        _aplicarEnquadramento(resultado.enquadramento);
      });
    } catch (e) {
      // `processarFotoEscolhida` já não lança por design, mas a leitura do
      // arquivo (`readAsBytes`) ou o canal de plataforma do ML Kit podem —
      // sem isso, o spinner de "_ajustando" ficava girando pra sempre.
      if (!mounted) return;
      setState(() {
        _ajustando = false;
        _erro = 'Não conseguimos processar essa foto. Tente escolher outra.';
      });
    }
  }

  void _aplicarEnquadramento(EnquadramentoAutomatico? enquadramento) {
    if (enquadramento == null) {
      _escala = 1.0;
      _offset = Offset.zero;
    } else {
      _escala = enquadramento.escala.clamp(1.0, 4.0);
      _offset = enquadramento.offset;
    }
  }

  void _escolherOutraFoto() {
    setState(() {
      _fotoProcessadaPng = null;
      _enquadramentoAutomatico = null;
      _erro = null;
      _avisoAjusteAutomatico = null;
    });
  }

  Future<void> _mostrarOpcoesDeFoto() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DalehColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: DalehColors.turf),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _escolherFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: DalehColors.turf),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(ctx).pop();
                _escolherFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    final Uint8List bytesPng;
    try {
      final imagem = await boundary.toImage(pixelRatio: 3);
      final bytesPorData = await imagem.toByteData(format: ui.ImageByteFormat.png);
      if (bytesPorData == null) throw Exception('toByteData devolveu null');
      bytesPng = bytesPorData.buffer.asUint8List();
    } catch (e) {
      // Achatar o card num PNG é uma etapa puramente local (sem rede) —
      // mas se falhar (ex: boundary ainda não totalmente desenhado), o
      // botão "CONFIRMAR FOTO" ficava girando o spinner pra sempre, sem
      // nenhuma mensagem, parecendo que o app travou.
      if (!mounted) return;
      setState(() => _erro = 'Não conseguimos preparar a foto final. Tente de novo.');
      return;
    }

    final erro = await ref.read(editarFotoControllerProvider.notifier).enviarAvatar(bytesPng);
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
          if (_fotoProcessadaPng == null && !_ajustando) ...[
            const Text(
              'Escolha uma foto de frente, com o rosto visível.',
              style: TextStyle(color: DalehColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _mostrarOpcoesDeFoto, child: const Text('ESCOLHER FOTO')),
            // Erro ocorrido antes de haver qualquer foto escolhida (ex:
            // permissão de câmera/galeria negada) — sem isso, a mensagem
            // era setada no state mas nunca aparecia na tela, porque esse
            // é o único ramo renderizado quando ainda não existe foto
            // processada. Pro usuário, parecia que nada tinha acontecido
            // ao tocar em Câmera/Galeria (achado ao escrever o teste desta
            // correção — o app não travava, mas também não avisava nada).
            if (_erro != null) ...[
              const SizedBox(height: 16),
              Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
            ],
          ] else ...[
            const Text(
              'Pronto! Se quiser, arraste pra reposicionar a cabeça e pinça pra ajustar o tamanho.',
              style: TextStyle(color: DalehColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Center(child: _canvas()),
            if (_ajustando) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.turf),
                ),
              ),
            ],
            if (_avisoAjusteAutomatico != null) ...[
              const SizedBox(height: 12),
              Text(_avisoAjusteAutomatico!, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: DalehColors.danger)),
            ],
            const SizedBox(height: 16),
            if (!_ajustando) ...[
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _enquadramentoAutomatico == null
                          ? null
                          : () => setState(() => _aplicarEnquadramento(_enquadramentoAutomatico)),
                      child: const Text('Redefinir automático'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _escolherOutraFoto,
                      child: const Text('Escolher outra'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fotoProcessadaPng == null || estado.enviando ? null : _salvar,
                child: estado.enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.bg),
                      )
                    : const Text('CONFIRMAR FOTO'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _canvas() {
    return GestureDetector(
      onScaleStart: _fotoProcessadaPng == null ? null : (_) => _escalaBase = _escala,
      onScaleUpdate: _fotoProcessadaPng == null
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
          ],
        ),
      ),
    );
  }

  Widget _cardFoto() {
    return ClipPath(
      clipper: const ClipFotoJogador(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final altura = constraints.maxHeight;
          final largura = constraints.maxWidth;
          final maxDx = (_escala - 1) * largura / 2;
          final maxDy = (_escala - 1) * altura / 2;
          final dx = _offset.dx > maxDx ? maxDx : (_offset.dx < -maxDx ? -maxDx : _offset.dx);
          final dy = _offset.dy > maxDy ? maxDy : (_offset.dy < -maxDy ? -maxDy : _offset.dy);

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [DalehColors.surface2, DalehColors.bg],
              ),
            ),
            child: ClipRect(
              child: _fotoProcessadaPng == null
                  ? const Center(child: Icon(Icons.person_outline, size: 64, color: DalehColors.muted))
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(dx, dy)
                        ..scale(_escala),
                      child: SizedBox(
                        width: largura,
                        height: altura,
                        child: Image.memory(_fotoProcessadaPng!, fit: BoxFit.cover),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

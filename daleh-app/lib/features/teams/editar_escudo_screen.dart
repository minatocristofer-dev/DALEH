import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/daleh_theme.dart';
import 'teams_providers.dart';

/// Trocar o escudo do time — bem mais simples que `EditarFotoScreen` (sem
/// oval, sem camisa): o backend só guarda a imagem do jeito que o usuário
/// escolheu, sem nenhuma composição. Só dono/capitão/vice-capitão consegue
/// abrir essa tela (checado em `team_detail_screen.dart`, e checado de novo
/// no backend).
class EditarEscudoScreen extends ConsumerStatefulWidget {
  final String teamId;
  const EditarEscudoScreen({super.key, required this.teamId});

  @override
  ConsumerState<EditarEscudoScreen> createState() => _EditarEscudoScreenState();
}

class _EditarEscudoScreenState extends ConsumerState<EditarEscudoScreen> {
  final _picker = ImagePicker();

  Uint8List? _imagem;
  String _contentType = 'image/jpeg';
  bool _enviando = false;
  String? _erro;

  Future<void> _escolherImagem(ImageSource origem) async {
    final arquivo = await _picker.pickImage(source: origem, imageQuality: 90);
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    setState(() {
      _imagem = bytes;
      _contentType = _inferirContentType(arquivo);
      _erro = null;
    });
  }

  // `XFile.mimeType` nem sempre vem preenchido (depende da plataforma/fonte
  // da imagem) — quando falta, cai pra extensão do nome do arquivo. PNG só
  // quando dá pra ter certeza; o padrão é JPEG (formato mais comum de
  // câmera/galeria).
  String _inferirContentType(XFile arquivo) {
    if (arquivo.mimeType != null && arquivo.mimeType!.isNotEmpty) return arquivo.mimeType!;
    if (arquivo.name.toLowerCase().endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }

  Future<void> _salvar() async {
    final imagem = _imagem;
    if (imagem == null) return;

    setState(() => _enviando = true);
    final erro = await ref.read(teamsActionsProvider).enviarEscudo(widget.teamId, imagem, _contentType);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escudo do time')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Escolha uma foto do escudo/logo do time.',
            style: TextStyle(color: DalehColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DalehRadius.lg),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: DalehColors.line), color: DalehColors.surface2),
                  child: _imagem == null
                      ? const Center(child: Icon(Icons.shield_outlined, size: 64, color: DalehColors.muted))
                      : Image.memory(_imagem!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherImagem(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Câmera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _escolherImagem(ImageSource.gallery),
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
            onPressed: _imagem == null || _enviando ? null : _salvar,
            child: _enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.bg),
                  )
                : const Text('Salvar escudo'),
          ),
        ],
      ),
    );
  }
}

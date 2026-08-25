import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captura o widget marcado por [chave] (precisa estar dentro de um
/// `RepaintBoundary`) como PNG e abre a folha de compartilhamento nativa do
/// sistema (Android/iOS) — não integra com nenhuma rede social específica,
/// só usa o mecanismo do próprio SO, que já sabe listar WhatsApp/Instagram/
/// etc. instalados no aparelho.
///
/// Nunca lança: qualquer falha (RepaintBoundary ainda não desenhado,
/// compartilhamento indisponível na plataforma, plugin ausente em ambiente
/// de teste) devolve `false`, pra tela decidir mostrar um aviso em vez de
/// crashar.
Future<bool> compartilharPlayerCard(GlobalKey chave, {String? texto}) async {
  try {
    final boundary = chave.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return false;

    final imagem = await boundary.toImage(pixelRatio: 3);
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return false;

    final diretorio = await getTemporaryDirectory();
    final caminho = '${diretorio.path}/daleh_player_card_${DateTime.now().millisecondsSinceEpoch}.png';
    final arquivo = await File(caminho).writeAsBytes(bytes.buffer.asUint8List());

    await Share.shareXFiles([XFile(arquivo.path)], text: texto);
    return true;
  } catch (_) {
    return false;
  }
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Serviço comum de compartilhamento visual do DALEH (QA Round 2, Priority
/// 5 — "não quero implementações separadas e duplicadas"): captura o widget
/// marcado por [chave] (precisa estar dentro de um `RepaintBoundary`) como
/// PNG e abre a folha de compartilhamento nativa do sistema. Usado pelo
/// Player Card e reutilizável por qualquer card novo (súmula, escalação,
/// confronto) sem duplicar essa lógica.
///
/// Nunca lança: qualquer falha (RepaintBoundary ainda não desenhado,
/// compartilhamento indisponível na plataforma, plugin ausente em ambiente
/// de teste) devolve `false`, pra tela decidir mostrar um aviso em vez de
/// crashar.
Future<bool> compartilharImagem(GlobalKey chave, {String? texto, String prefixoArquivo = 'daleh'}) async {
  try {
    final boundary = chave.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return false;

    final imagem = await boundary.toImage(pixelRatio: 3);
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return false;

    final diretorio = await getTemporaryDirectory();
    final caminho = '${diretorio.path}/${prefixoArquivo}_${DateTime.now().millisecondsSinceEpoch}.png';
    final arquivo = await File(caminho).writeAsBytes(bytes.buffer.asUint8List());

    await Share.shareXFiles([XFile(arquivo.path)], text: texto);
    return true;
  } catch (_) {
    return false;
  }
}

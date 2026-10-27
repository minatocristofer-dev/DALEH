import 'package:flutter/widgets.dart';
import '../../shared/compartilhar_imagem.dart';

/// Fino wrapper sobre o serviço comum de compartilhamento (ver
/// `compartilharImagem`) — mantido com esse nome só por compatibilidade com
/// quem já chama `compartilharPlayerCard` (não duplica a lógica de captura).
Future<bool> compartilharPlayerCard(GlobalKey chave, {String? texto}) {
  return compartilharImagem(chave, texto: texto, prefixoArquivo: 'daleh_player_card');
}

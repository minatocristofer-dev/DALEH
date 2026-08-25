import 'package:flutter/material.dart';
import '../../../shared/widgets/primary_button.dart';
import '../models/meu_perfil.dart';
import '../player_card_share.dart';
import 'player_card.dart';

/// `PlayerCard` + botão "COMPARTILHAR PLAYER CARD", reaproveitado tanto pela
/// tela do próprio perfil quanto pela tela de perfil público de outro
/// jogador (Fase 7) — a lógica de captura/compartilhamento é a mesma nos
/// dois casos, só muda de quem é o `MeuPerfil` exibido.
class PlayerCardComCompartilhar extends StatefulWidget {
  final MeuPerfil perfil;
  const PlayerCardComCompartilhar({super.key, required this.perfil});

  @override
  State<PlayerCardComCompartilhar> createState() => _PlayerCardComCompartilharState();
}

class _PlayerCardComCompartilharState extends State<PlayerCardComCompartilhar> {
  final _cardKey = GlobalKey();
  bool _compartilhando = false;

  Future<void> _compartilhar() async {
    setState(() => _compartilhando = true);
    final sucesso = await compartilharPlayerCard(
      _cardKey,
      texto: 'A carta de ${widget.perfil.fullName} no DALEH.',
    );
    if (mounted) {
      setState(() => _compartilhando = false);
      if (!sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar agora. Tenta de novo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(key: _cardKey, child: PlayerCard(perfil: widget.perfil)),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'COMPARTILHAR PLAYER CARD',
          icon: Icons.share_outlined,
          carregando: _compartilhando,
          onPressed: _compartilhar,
        ),
      ],
    );
  }
}

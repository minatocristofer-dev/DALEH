import 'package:flutter/material.dart';
import 'desafios_tab.dart';
import 'meus_jogos_tab.dart';

/// Raiz da aba "Jogos": dois grandes blocos que o backend já sustenta hoje —
/// jogo avulso (Meus Jogos) e desafio entre times (Desafios). Ligação entre
/// os dois (torneio, quadra reservada de verdade) fica pra depois, conforme
/// a auditoria da Fase 2.0.
class JogosRootScreen extends StatelessWidget {
  final int abaInicial;
  const JogosRootScreen({super.key, this.abaInicial = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: abaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jogos'),
          bottom: const TabBar(tabs: [Tab(text: 'MEUS JOGOS'), Tab(text: 'DESAFIOS')]),
        ),
        body: const TabBarView(children: [MeusJogosTab(), DesafiosTab()]),
      ),
    );
  }
}

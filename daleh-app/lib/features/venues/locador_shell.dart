import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import 'minhas_quadras_screen.dart';

/// Navegação de quem escolheu "Locador" no Seletor de Modo — só a gestão de
/// quadras (horários, reservas, bloqueios), nada de Times/Jogos/Perfil de
/// jogador. É a mesma conta de sempre, só que com um conjunto de telas
/// diferente (ver AuthStorage.ModoAcesso).
class LocadorShell extends ConsumerWidget {
  const LocadorShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Quadras'),
        actions: [
          IconButton(
            tooltip: 'Trocar modo',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(authControllerProvider.notifier).abrirSeletorDeModo(),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).sair(),
          ),
        ],
      ),
      body: const MinhasQuadrasBody(),
    );
  }
}

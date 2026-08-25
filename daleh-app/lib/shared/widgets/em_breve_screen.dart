import 'package:flutter/material.dart';
import 'empty_state.dart';

/// Placeholder honesto pras áreas que ainda não foram construídas (Início,
/// Jogos, Explorar) — nada de dado fake, só avisa que a área vem numa
/// próxima fase.
class EmBreveScreen extends StatelessWidget {
  final IconData icon;
  final String titulo;

  const EmBreveScreen({super.key, required this.icon, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      titulo: titulo,
      subtitulo: 'Essa área ainda está sendo construída. Em breve por aqui.',
    );
  }
}

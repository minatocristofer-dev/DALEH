import 'package:flutter/material.dart';
import '../theme/daleh_theme.dart';
import 'home/inicio_screen.dart';
import 'matches/jogos_root_screen.dart';
import 'perfil/perfil_screen.dart';
import 'teams/meus_times_screen.dart';
import 'venues/explorar_quadras_screen.dart';

/// Navegação principal do app: bottom nav com 5 áreas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _aba = 0; // começa em Início

  @override
  Widget build(BuildContext context) {
    final telas = [
      InicioScreen(onNavegarParaAba: (aba) => setState(() => _aba = aba)),
      const MeusTimesScreen(),
      const JogosRootScreen(),
      const ExplorarQuadrasScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _aba, children: telas),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        backgroundColor: DalehColors.surface,
        indicatorColor: DalehColors.turf.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Times'),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Jogos',
          ),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

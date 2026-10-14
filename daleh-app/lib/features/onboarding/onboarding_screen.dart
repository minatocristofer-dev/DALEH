import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

class _PaginaOnboarding {
  final IconData icone;
  final String titulo;
  final String texto;
  const _PaginaOnboarding({required this.icone, required this.titulo, required this.texto});
}

const _paginas = [
  _PaginaOnboarding(
    icone: Icons.sports_soccer,
    titulo: 'Jogue',
    texto: 'Entre em peladas, desafie outros times e acompanhe suas estatísticas.',
  ),
  _PaginaOnboarding(
    icone: Icons.workspace_premium_outlined,
    titulo: 'Organize',
    texto: 'Gerencie seu time, sua quadra ou seus horários — tudo num só lugar.',
  ),
  _PaginaOnboarding(
    icone: Icons.auto_graph,
    titulo: 'Construa sua história',
    texto: 'Cada jogo fica registrado na sua carteirinha digital, pra sempre.',
  ),
];

/// Onboarding mínimo, mostrado uma única vez (ver
/// `AuthStorage.salvarOnboardingVisto`) antes da tela de login/cadastro.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onConcluir;
  const OnboardingScreen({super.key, required this.onConcluir});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controlador = PageController();
  int _pagina = 0;

  @override
  Widget build(BuildContext context) {
    final ultima = _pagina == _paginas.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onConcluir,
                child: const Text('Pular', style: TextStyle(color: DalehColors.muted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controlador,
                itemCount: _paginas.length,
                onPageChanged: (i) => setState(() => _pagina = i),
                itemBuilder: (context, i) {
                  final pagina = _paginas[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(24)),
                          child: Icon(pagina.icone, color: DalehColors.bg, size: 44),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          pagina.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pagina.texto,
                          style: const TextStyle(color: DalehColors.muted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _paginas.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _pagina ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _pagina ? DalehColors.turf : DalehColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (ultima) {
                    widget.onConcluir();
                  } else {
                    _controlador.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                  }
                },
                child: Text(ultima ? 'Começar' : 'Próximo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

// As 3 peças já são composições completas (wordmark + título + texto +
// visual, no padrão DALEH) — por isso o onboarding não desenha nenhum
// título/subtítulo próprio por cima, só os controles de navegação
// (Pular/dots/botão) flutuando sobre a imagem em tela cheia.
const _assets = [
  'assets/onboarding/encontre_seu_jogo.png',
  'assets/onboarding/gerencie_seu_time.png',
  'assets/onboarding/controle_sua_quadra.png',
];

/// Onboarding mostrado uma única vez (ver `AuthStorage.salvarOnboardingVisto`)
/// antes da tela de login/cadastro.
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
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ultima = _pagina == _assets.length - 1;

    return Scaffold(
      backgroundColor: DalehColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controlador,
            itemCount: _assets.length,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (context, i) => Image.asset(_assets[i], fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DalehSpacing.xxl),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: widget.onConcluir,
                      style: TextButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.35)),
                      child: const Text('Pular', style: TextStyle(color: DalehColors.text)),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _assets.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _pagina ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _pagina ? DalehColors.turf : DalehColors.text.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(DalehRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: DalehSpacing.xxl),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (ultima) {
                            widget.onConcluir();
                          } else {
                            _controlador.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                          }
                        },
                        child: Text(ultima ? 'COMEÇAR AGORA' : 'PRÓXIMO'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

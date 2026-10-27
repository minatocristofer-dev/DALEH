import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

const _logoAsset = 'assets/icon/app_icon.png';

/// Tela de abertura — mostrada só enquanto a sessão salva é lida do storage
/// (`AuthState.verificandoSessao`, ver `_Raiz` em `app.dart`). Puramente
/// visual: logo + assinatura da marca + barra de progresso decorativa, sem
/// nenhum botão/campo/lógica própria. A animação é de execução única (nunca
/// repete) pra não travar `pumpAndSettle()` nos testes de widget.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _opacidadeLogo;
  late final Animation<double> _escalaLogo;
  late final Animation<double> _progresso;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _opacidadeLogo = CurvedAnimation(parent: _controlador, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _escalaLogo = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controlador, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _progresso = CurvedAnimation(parent: _controlador, curve: const Interval(0.25, 1.0, curve: Curves.easeInOut));
    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DalehColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            FadeTransition(
              opacity: _opacidadeLogo,
              child: ScaleTransition(
                scale: _escalaLogo,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DalehRadius.xl),
                  child: Image.asset(_logoAsset, width: 180, height: 180, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _opacidadeLogo,
              child: const Text(
                'Cada jogo constrói sua história.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DalehColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(flex: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: AnimatedBuilder(
                animation: _progresso,
                builder: (context, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(DalehRadius.pill),
                  child: LinearProgressIndicator(
                    value: _progresso.value,
                    minHeight: 4,
                    backgroundColor: DalehColors.line,
                    valueColor: const AlwaysStoppedAnimation(DalehColors.turf),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

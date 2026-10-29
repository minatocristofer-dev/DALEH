import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/auth/seletor_modo_screen.dart';
import 'features/dirigente/dirigente_shell.dart';
import 'features/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/venues/locador_shell.dart';
import 'core/auth_storage.dart';
import 'shared/widgets/daleh_wordmark.dart';
import 'theme/daleh_theme.dart';

class DalehApp extends StatelessWidget {
  const DalehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DALEH',
      debugShowCheckedModeBanner: false,
      theme: buildDalehTheme(),
      home: const _Raiz(),
    );
  }
}

class _Raiz extends ConsumerStatefulWidget {
  const _Raiz();

  @override
  ConsumerState<_Raiz> createState() => _RaizState();
}

enum _TelaAuth { login, cadastro }

class _RaizState extends ConsumerState<_Raiz> {
  _TelaAuth telaAuth = _TelaAuth.login;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    // Splash: enquanto a sessão salva ainda está sendo lida do storage.
    if (auth.verificandoSessao) {
      return const SplashScreen();
    }

    // Onboarding: mostrado uma única vez, só pra quem ainda não tem sessão
    // (nunca interrompe quem já está logado).
    if (!auth.logado && !auth.onboardingVisto) {
      return OnboardingScreen(onConcluir: () => ref.read(authControllerProvider.notifier).concluirOnboarding());
    }

    if (auth.logado) {
      // Seletor de Modo: aparece depois de todo login/cadastro novo (nunca
      // em sessão restaurada) e também quando o usuário pede "Trocar modo"
      // dentro do app, sem precisar deslogar.
      if (auth.mostrarSeletorModo) {
        return const SeletorModoScreen();
      }
      // Mesma conta, três conjuntos de telas diferentes — o modo escolhido
      // aqui NUNCA concede permissão nenhuma por si só (ver
      // AuthStorage.ModoAcesso); quem autoriza é sempre o backend.
      switch (auth.modoAcesso) {
        case ModoAcesso.locador:
          return const LocadorShell();
        case ModoAcesso.dirigente:
          return const DirigenteShell();
        case ModoAcesso.jogador:
          return const HomeShell();
      }
    }

    // Login tem Scaffold/visual próprios (fundo de estádio em tela cheia,
    // fora do card compartilhado) — só o Cadastro continua no layout antigo
    // (fora do escopo da nova tela de login).
    if (telaAuth == _TelaAuth.login) {
      return LoginScreen(onIrParaCadastro: () => setState(() => telaAuth = _TelaAuth.cadastro));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cabecalho(),
                  const SizedBox(height: 16),
                  CadastroScreen(onIrParaLogin: () => setState(() => telaAuth = _TelaAuth.login)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Cabeçalho do Cadastro (Login não usa mais — tem visual próprio).
  Widget _cabecalho() {
    const subtitulo = 'Crie sua conta';
    const icone = Icons.person_add_alt_1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // "Entre na sua conta"/"Crie sua conta" são mais longos que o texto
          // fixo de antes — sem o Expanded, estourava por cima do ícone (bug
          // achado em QA real, capturado pelo teste de overflow).
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DalehWordmark(size: 13),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: DalehColors.bg, size: 18),
          ),
        ],
      ),
    );
  }
}

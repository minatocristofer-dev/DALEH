import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/perfil/perfil_screen.dart';
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
                  if (auth.verificandoSessao)
                    const Center(child: CircularProgressIndicator(color: DalehColors.turf))
                  else if (!auth.logado)
                    telaAuth == _TelaAuth.login
                        ? LoginScreen(onIrParaCadastro: () => setState(() => telaAuth = _TelaAuth.cadastro))
                        : CadastroScreen(onIrParaLogin: () => setState(() => telaAuth = _TelaAuth.login))
                  else
                    const PerfilScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DALEH', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              Text('O básico do app', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.groups, color: DalehColors.bg, size: 18),
          ),
        ],
      ),
    );
  }
}

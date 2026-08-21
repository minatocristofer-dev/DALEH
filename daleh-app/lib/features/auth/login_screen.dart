import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/daleh_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onIrParaCadastro;
  const LoginScreen({super.key, required this.onIrParaCadastro});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String? _erro;

  Future<void> _entrar() async {
    setState(() => _erro = null);
    final erro = await ref.read(authControllerProvider.notifier).login(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (erro != null) setState(() => _erro = erro);
  }

  @override
  Widget build(BuildContext context) {
    final carregando = ref.watch(authControllerProvider).carregando;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.login, color: DalehColors.turf, size: 20),
                SizedBox(width: 8),
                Text('Entrar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'E-MAIL', hintText: 'voce@exemplo.com'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _senhaCtrl,
              decoration: const InputDecoration(labelText: 'SENHA'),
              obscureText: true,
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: DalehColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: carregando ? null : _entrar,
              child: Text(carregando ? 'Entrando…' : 'Entrar'),
            ),
            const SizedBox(height: 16),
            Row(children: const [
              Expanded(child: Divider(color: DalehColors.line)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('ou', style: TextStyle(color: DalehColors.muted, fontSize: 11))),
              Expanded(child: Divider(color: DalehColors.line)),
            ]),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(authControllerProvider.notifier).entrarComGoogle(),
              child: const Text('Entrar com Google'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ainda não tem conta?', style: TextStyle(color: DalehColors.muted, fontSize: 12)),
                TextButton(
                  onPressed: widget.onIrParaCadastro,
                  child: const Text('Cadastre-se', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

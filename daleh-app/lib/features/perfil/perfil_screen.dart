import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_storage.dart';
import '../../theme/daleh_theme.dart';
import '../auth/auth_controller.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authControllerProvider).token ?? '';
    final payload = AuthStorage.payloadDoToken(token);
    final email = payload?['email']?.toString() ?? '';
    final inicial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: DalehColors.turf,
                  child: Text(inicial, style: const TextStyle(color: DalehColors.bg, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jogador', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(email, style: const TextStyle(color: DalehColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Sessão válida — o token de acesso já está sendo enviado nas chamadas pra API real do DALEH.',
              style: TextStyle(color: DalehColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).sair(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

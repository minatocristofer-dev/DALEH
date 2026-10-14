import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_storage.dart';
import '../../theme/daleh_theme.dart';
import 'auth_controller.dart';

/// Tela mostrada uma vez por login (nunca em sessão restaurada) e também a
/// partir de "Trocar modo" dentro do app. Escolher um modo aqui só decide
/// qual conjunto de telas abre a seguir — nunca concede nenhuma permissão:
/// quem autoriza de verdade continua sendo o backend (ver
/// `TeamDetail.possoGerenciar`, `VenuesService.exigirDono`).
class SeletorModoScreen extends ConsumerWidget {
  const SeletorModoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modoAtual = ref.watch(authControllerProvider).modoAcesso;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Como você quer usar\no DALEH agora?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, height: 1.2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você pode trocar quando quiser, sem precisar sair da conta.',
                style: TextStyle(color: DalehColors.muted),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: [
                    _CardModo(
                      icone: Icons.sports_soccer,
                      titulo: 'JOGADOR',
                      descricao: 'Jogue, acompanhe suas estatísticas e construa sua história.',
                      selecionado: modoAtual == ModoAcesso.jogador,
                      onTap: () => ref.read(authControllerProvider.notifier).definirModoAcesso(ModoAcesso.jogador),
                    ),
                    const SizedBox(height: 14),
                    _CardModo(
                      icone: Icons.workspace_premium_outlined,
                      titulo: 'DIRIGENTE',
                      descricao: 'Crie e gerencie seu time, organize jogos e cuide do elenco.',
                      selecionado: modoAtual == ModoAcesso.dirigente,
                      onTap: () => ref.read(authControllerProvider.notifier).definirModoAcesso(ModoAcesso.dirigente),
                    ),
                    const SizedBox(height: 14),
                    _CardModo(
                      icone: Icons.stadium_outlined,
                      titulo: 'LOCADOR',
                      descricao: 'Gerencie sua quadra, horários e reservas.',
                      selecionado: modoAtual == ModoAcesso.locador,
                      onTap: () => ref.read(authControllerProvider.notifier).definirModoAcesso(ModoAcesso.locador),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardModo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final bool selecionado;
  final VoidCallback onTap;

  const _CardModo({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DalehColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selecionado ? DalehColors.turf : DalehColors.line, width: selecionado ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: DalehColors.bg, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(descricao, style: const TextStyle(color: DalehColors.muted, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: selecionado ? DalehColors.turf : DalehColors.muted),
          ],
        ),
      ),
    );
  }
}

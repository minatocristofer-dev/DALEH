import 'package:flutter/material.dart';
import '../../features/perfil/perfil_publico_screen.dart';
import '../../features/teams/models/team_member.dart';
import '../../theme/daleh_theme.dart';
import 'crest_avatar.dart';
import 'status_chip.dart';

class MemberRow extends StatelessWidget {
  final TeamMember membro;
  final bool ehDono;
  final bool possoGerenciar;
  final bool souEuMesmo;
  final void Function(String novoPapel)? onAlterarPapel;
  final VoidCallback? onRemover;

  const MemberRow({
    super.key,
    required this.membro,
    required this.ehDono,
    required this.possoGerenciar,
    required this.souEuMesmo,
    this.onAlterarPapel,
    this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    // Dono não tem o próprio papel alterado/removido por aqui — ele só sai do time excluindo o time (fora de escopo desta fase).
    final podeAgirNesteMembro = possoGerenciar && !ehDono;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PerfilPublicoScreen(userId: membro.userId)),
              ),
              child: Row(
                children: [
                  CrestAvatar(url: membro.avatarUrl, nome: membro.fullName, tamanho: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          souEuMesmo ? '${membro.fullName} (você)' : membro.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StatusChip.papel(membro.papel, souDono: ehDono),
                        const SizedBox(height: 4),
                        Text(
                          '${membro.estatisticas.jogos} jogos · ${membro.estatisticas.gols} gols · ${membro.estatisticas.mvp} MVP',
                          style: const TextStyle(color: DalehColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (podeAgirNesteMembro)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: DalehColors.muted),
              onSelected: (valor) {
                if (valor == 'remover') {
                  onRemover?.call();
                } else {
                  onAlterarPapel?.call(valor);
                }
              },
              itemBuilder: (context) => [
                if (membro.papel != 'JOGADOR') const PopupMenuItem(value: 'JOGADOR', child: Text('Definir como Jogador')),
                if (membro.papel != 'VICE_CAPITAO')
                  const PopupMenuItem(value: 'VICE_CAPITAO', child: Text('Definir como Vice-Capitão')),
                if (membro.papel != 'CAPITAO') const PopupMenuItem(value: 'CAPITAO', child: Text('Definir como Capitão')),
                if (membro.papel != 'TESOUREIRO')
                  const PopupMenuItem(value: 'TESOUREIRO', child: Text('Definir como Tesoureiro')),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remover',
                  child: Text('Remover do time', style: TextStyle(color: DalehColors.danger)),
                ),
              ],
            )
          else if (souEuMesmo && !ehDono)
            TextButton(
              onPressed: onRemover,
              child: const Text('Sair', style: TextStyle(color: DalehColors.danger)),
            ),
        ],
      ),
    );
  }
}

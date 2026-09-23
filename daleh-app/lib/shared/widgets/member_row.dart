import 'package:flutter/material.dart';
import '../../features/perfil/perfil_publico_screen.dart';
import '../../features/teams/models/team_member.dart';
import '../../theme/daleh_theme.dart';
import 'crest_avatar.dart';
import 'status_chip.dart';

/// Layout definido pelo mockup "TIME — ELENCO" (QA de 2026-09-21): foto,
/// nome, posição, e jogos/gols/MVPs em colunas. O papel de gestão
/// (capitão/vice/dono) continua aparecendo, só que discreto (badge ao lado
/// do nome, e só quando não é "jogador" comum) — informação real que já
/// existia, não dá pra simplesmente sumir. Número da camisa (quando o
/// administrador já definiu) aparece em destaque do lado do nome, do mesmo
/// jeito que numa camisa de verdade.
class MemberRow extends StatelessWidget {
  final TeamMember membro;
  final bool ehDono;
  final bool possoGerenciar;
  final bool souEuMesmo;
  final void Function(String novoPapel)? onAlterarPapel;
  final VoidCallback? onRemover;
  final VoidCallback? onEditarNumero;

  const MemberRow({
    super.key,
    required this.membro,
    required this.ehDono,
    required this.possoGerenciar,
    required this.souEuMesmo,
    this.onAlterarPapel,
    this.onRemover,
    this.onEditarNumero,
  });

  @override
  Widget build(BuildContext context) {
    // Dono não tem o próprio papel alterado/removido por aqui — ele só sai do time excluindo o time (fora de escopo desta fase).
    final podeAgirNesteMembro = possoGerenciar && !ehDono;
    final papelDeDestaque = ehDono || membro.papel != 'JOGADOR';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  CrestAvatar(url: membro.avatarUrl, nome: membro.fullName, tamanho: 44),
                  if (membro.numeroCamisa != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${membro.numeroCamisa}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                souEuMesmo ? '${membro.fullName} (você)' : membro.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (papelDeDestaque) ...[
                              const SizedBox(width: 6),
                              StatusChip.papel(membro.papel, souDono: ehDono),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          membro.posicaoPrincipal ?? 'Sem modalidade cadastrada',
                          style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _estatistica('JOGOS', membro.estatisticas.jogos),
                        _estatistica('GOLS', membro.estatisticas.gols),
                        _estatistica('MVPS', membro.estatisticas.mvp),
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
                } else if (valor == 'numero') {
                  onEditarNumero?.call();
                } else {
                  onAlterarPapel?.call(valor);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'numero',
                  child: Text(membro.numeroCamisa == null ? 'Definir número da camisa' : 'Trocar número da camisa'),
                ),
                const PopupMenuDivider(),
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
            )
          else
            const Icon(Icons.chevron_right, color: DalehColors.muted),
        ],
      ),
    );
  }

  Widget _estatistica(String label, int valor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$valor', style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: DalehColors.muted, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

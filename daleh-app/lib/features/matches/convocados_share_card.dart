import 'package:flutter/material.dart';
import '../../shared/compartilhar_imagem.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../shared/widgets/daleh_wordmark.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/daleh_theme.dart';
import 'models/match.dart';
import 'models/match_attendance.dart';
import 'sumula_widgets.dart' show formatarDataHora;

/// Card de compartilhamento dos CONVOCADOS (kit visual "Convocados V5"):
/// substitui a antiga `EscalacaoShareCard`, que agrupava confirmados por
/// time/posição num layout que lembrava formação tática. Regra inegociável
/// do kit: isto NÃO é escalação — todos os confirmados (`status == confirmed`)
/// entram numa ÚNICA lista vertical, com destaque igual, sem titular/reserva
/// nem jogador posicionado em quadra. O fundo é só ambientação por
/// modalidade (cenário real sem jogadores, sem texto) atrás da lista.
String _fundoConvocados(Match partida) {
  final label = partida.modalidadeLabel?.toLowerCase() ?? '';
  // Só temos cenário dedicado pra Futsal (ginásio) e Society/Campo (campo
  // externo) no kit — Campo 11 cai no mesmo cenário externo da Society por
  // ser a mesma família de ambiente (ao ar livre), nunca um fundo inventado.
  if (label.contains('futsal')) return 'assets/convocados/fundo_futsal.png';
  return 'assets/convocados/fundo_society.png';
}

class ConvocadosShareCard extends StatelessWidget {
  final Match partida;
  final List<MatchAttendance> confirmados;
  const ConvocadosShareCard({super.key, required this.partida, required this.confirmados});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DalehRadius.lg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 560),
        decoration: const BoxDecoration(color: DalehColors.bg),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Image.asset(_fundoConvocados(partida), fit: BoxFit.cover),
            ),
            // Degradê escuro: mais forte no topo (cabeçalho) e no rodapé
            // (última ficha), mais suave no meio — garante legibilidade do
            // texto sem apagar o cenário por trás (regra do kit: fundo
            // cobre todo o canvas, nunca uma máscara opaca).
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      DalehColors.bg.withValues(alpha: 0.90),
                      DalehColors.bg.withValues(alpha: 0.58),
                      DalehColors.bg.withValues(alpha: 0.70),
                      DalehColors.bg.withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.24, 0.6, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(child: DalehWordmark(size: 24)),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'CONVOCAÇÃO',
                      style: TextStyle(color: DalehColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Cabecalho(partida: partida),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      '${formatarDataHora(partida.scheduledAt)}${partida.venueName != null ? ' • ${partida.venueName}' : ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DalehColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FaixaConvocados(total: confirmados.length),
                  const SizedBox(height: 16),
                  if (confirmados.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Ninguém confirmado ainda.', style: TextStyle(color: DalehColors.muted, fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final a in confirmados) ...[
                          _FichaJogador(presenca: a),
                          if (a != confirmados.last) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho condicional: confronto real (nomes + escudos dos dois times)
/// quando a partida nasceu de um desafio aceito; caso contrário, fallback
/// seguro pra modalidade/local — nunca inventa um adversário.
class _Cabecalho extends StatelessWidget {
  final Match partida;
  const _Cabecalho({required this.partida});

  @override
  Widget build(BuildContext context) {
    if (!partida.temTimes) {
      return Center(
        child: Text(
          partida.modalidadeLabel ?? 'Partida',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: DalehColors.text),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _ladoDoTime(partida.homeTeamCrestUrl, partida.homeTeamName ?? 'Time A')),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('VS', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        Expanded(child: _ladoDoTime(partida.awayTeamCrestUrl, partida.awayTeamName ?? 'Time B')),
      ],
    );
  }

  Widget _ladoDoTime(String? crestUrl, String nome) {
    return Column(
      children: [
        CrestAvatar(url: crestUrl, nome: nome, tamanho: 40),
        const SizedBox(height: 6),
        Text(
          nome,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: DalehColors.text),
        ),
      ],
    );
  }
}

/// Faixa diagonal "CONVOCADOS" + contador real de confirmados — elemento
/// de maior destaque do card (regra do kit: "mais destaque e impacto").
class _FaixaConvocados extends StatelessWidget {
  final int total;
  const _FaixaConvocados({required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipPath(
            clipper: _FaixaClipper(),
            child: Container(
              color: DalehColors.turf,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              child: const Text(
                'CONVOCADOS',
                style: TextStyle(color: DalehColors.bg, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: DalehColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(DalehRadius.md),
            border: Border.all(color: DalehColors.turf, width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total', style: const TextStyle(color: DalehColors.text, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: DalehColors.turf, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _FaixaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const corte = 12.0;
    return Path()
      ..moveTo(corte, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - corte, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Uma linha da lista vertical de convocados: foto, número de camisa (quando
/// existir vínculo com o time), nome e posição (quando cadastrada) — nunca
/// inventados. Todas as linhas têm o MESMO destaque (regra: sem titular vs
/// reserva).
class _FichaJogador extends StatelessWidget {
  final MatchAttendance presenca;
  const _FichaJogador({required this.presenca});

  @override
  Widget build(BuildContext context) {
    final nome = presenca.userFullName ?? 'Jogador';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DalehColors.bg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(DalehRadius.md),
        border: Border.all(color: DalehColors.turf.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CrestAvatar(url: presenca.userAvatarUrl, nome: nome, tamanho: 38),
          const SizedBox(width: 10),
          if (presenca.numeroCamisa != null) ...[
            SizedBox(
              width: 26,
              child: Text(
                '${presenca.numeroCamisa}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: DalehColors.text, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          if (presenca.posicaoPrincipal != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DalehRadius.pill),
                border: Border.all(color: DalehColors.turf.withValues(alpha: 0.6)),
              ),
              child: Text(
                presenca.posicaoPrincipal!.toUpperCase(),
                style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botão "COMPARTILHAR CONVOCADOS" — abre o card numa folha modal rolável
/// (pra não estourar a tela com grupos grandes) em vez de deixá-lo sempre
/// visível na aba Participantes.
class ConvocadosShareButton extends StatelessWidget {
  final Match partida;
  final List<MatchAttendance> confirmados;
  const ConvocadosShareButton({super.key, required this.partida, required this.confirmados});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'COMPARTILHAR CONVOCADOS',
      icon: Icons.share_outlined,
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: DalehColors.surface,
        builder: (ctx) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (ctx, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: _ConvocadosSharePreview(partida: partida, confirmados: confirmados),
          ),
        ),
      ),
    );
  }
}

class _ConvocadosSharePreview extends StatefulWidget {
  final Match partida;
  final List<MatchAttendance> confirmados;
  const _ConvocadosSharePreview({required this.partida, required this.confirmados});

  @override
  State<_ConvocadosSharePreview> createState() => _ConvocadosSharePreviewState();
}

class _ConvocadosSharePreviewState extends State<_ConvocadosSharePreview> {
  final _cardKey = GlobalKey();
  bool _compartilhando = false;

  Future<void> _compartilhar() async {
    setState(() => _compartilhando = true);
    final sucesso = await compartilharImagem(_cardKey, texto: 'Convocados confirmados no DALEH.', prefixoArquivo: 'daleh_convocados');
    if (mounted) {
      setState(() => _compartilhando = false);
      if (!sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar agora. Tenta de novo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(key: _cardKey, child: ConvocadosShareCard(partida: widget.partida, confirmados: widget.confirmados)),
        const SizedBox(height: 14),
        PrimaryButton(label: 'COMPARTILHAR CONVOCADOS', icon: Icons.share_outlined, carregando: _compartilhando, onPressed: _compartilhar),
      ],
    );
  }
}

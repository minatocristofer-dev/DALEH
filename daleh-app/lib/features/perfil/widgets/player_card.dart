import 'package:flutter/material.dart';
import '../../../shared/widgets/crest_avatar.dart';
import '../../../theme/daleh_theme.dart';
import '../models/meu_perfil.dart';

/// A "carta de jogador" do DALEH — identidade visual própria (gradiente
/// campo-à-noite + lima + âmbar já usados no resto do app, textura de
/// listras diagonais como a do padrão `fm-stripes` do protótipo original),
/// sem copiar nenhum elemento gráfico de FIFA/EA FC/Ultimate Team. Só mostra
/// dado real: nada de overall, número de camisa ou vitórias/derrotas, porque
/// o backend não tem isso (ver Fase 6/7 — auditoria). Genérico o bastante
/// pra representar tanto o próprio jogador quanto o perfil público de
/// outro (Fase 7) — não depende de "ser meu perfil" em nada.
class PlayerCard extends StatelessWidget {
  final MeuPerfil perfil;
  const PlayerCard({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final modalidadePrincipal = perfil.modalidadePrincipal;
    final localizacao = [perfil.city, perfil.state].where((v) => v != null && v.isNotEmpty).join(' / ');
    // Idade só entra na linha quando existir (a maioria dos perfis ainda não
    // tem data de nascimento cadastrada — ver Fase 9, model MeuPerfil).
    final infoSecundaria = [
      if (perfil.idade != null) '${perfil.idade} anos',
      if (localizacao.isNotEmpty) localizacao,
    ].join(' · ');
    final e = perfil.estatisticas;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DalehColors.surface2, DalehColors.bg],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DalehColors.turf.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: DalehColors.turf.withOpacity(0.15), blurRadius: 24, spreadRadius: -4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.5),
        child: Stack(
          children: [
            const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ListrasDiagonais()))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _seloDaleh(),
                      if (modalidadePrincipal != null) _badgePosicao(modalidadePrincipal.posicaoPrincipal),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(child: _avatarComBrilho()),
                  const SizedBox(height: 14),
                  Text(
                    perfil.fullName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DalehColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (infoSecundaria.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      infoSecundaria,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DalehColors.muted, fontSize: 12),
                    ),
                  ],
                  if (perfil.dominantFoot != null) ...[
                    const SizedBox(height: 10),
                    Center(child: _chipModalidade('Pé ${perfil.dominantFoot}')),
                  ],
                  if (perfil.modalidades.length > 1) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          perfil.modalidades.map((m) => _chipModalidade('${m.label}: ${m.posicaoPrincipal}')).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Divider(color: DalehColors.line, height: 1),
                  const SizedBox(height: 14),
                  _linhaTimes(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _estatistica('JOGOS', e.jogosDisputados),
                      _estatistica('GOLS', e.gols),
                      _estatistica('ASSISTS', e.assistencias),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _estatistica('MVP', e.mvp, cor: DalehColors.amber),
                      _estatistica('AMARELOS', e.cartoesAmarelos, cor: DalehColors.amber),
                      _estatistica('VERMELHOS', e.cartoesVermelhos, cor: DalehColors.danger),
                    ],
                  ),
                  if (perfil.bio != null && perfil.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Divider(color: DalehColors.line, height: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'SOBRE',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DalehColors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      perfil.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DalehColors.text, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Divider(color: DalehColors.line, height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    '"Cada jogo constrói sua história."',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DalehColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'EVERY MATCH BUILDS YOUR LEGACY.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DalehColors.amber, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seloDaleh() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: DalehColors.amber, width: 1.2)),
          child: const Icon(Icons.sports_soccer, size: 11, color: DalehColors.amber),
        ),
        const SizedBox(width: 6),
        const Text(
          'DALEH PLAYER',
          style: TextStyle(color: DalehColors.amber, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _avatarComBrilho() {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [DalehColors.turf.withOpacity(0.28), Colors.transparent]),
            ),
          ),
          CrestAvatar(url: perfil.avatarUrl, nome: perfil.fullName, tamanho: 96),
        ],
      ),
    );
  }

  Widget _badgePosicao(String posicao) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DalehColors.turf.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DalehColors.turf.withOpacity(0.6)),
      ),
      child: Text(
        posicao.toUpperCase(),
        style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  Widget _chipModalidade(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DalehColors.line),
      ),
      child: Text(texto, style: const TextStyle(color: DalehColors.text, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _linhaTimes() {
    if (perfil.timesAtuais.isEmpty) {
      return const Text(
        'Sem time no momento',
        textAlign: TextAlign.center,
        style: TextStyle(color: DalehColors.muted, fontSize: 12),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 10,
      children: perfil.timesAtuais.map((t) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CrestAvatar(url: t.crestUrl, nome: t.name, tamanho: 36),
            const SizedBox(height: 4),
            Text(t.name, style: const TextStyle(color: DalehColors.text, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        );
      }).toList(),
    );
  }

  Widget _estatistica(String label, int valor, {Color cor = DalehColors.text}) {
    return Expanded(
      child: Column(
        children: [
          Text('$valor', style: TextStyle(color: cor, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: DalehColors.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// Textura de fundo discreta — listras diagonais na cor da grama (lima),
/// bem baixa opacidade. Mesmo conceito do padrão `fm-stripes` já
/// referenciado como identidade DALEH desde o protótipo original
/// (`fullmatch-core.jsx`), não um elemento novo/copiado de terceiros.
class _ListrasDiagonais extends CustomPainter {
  const _ListrasDiagonais();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DalehColors.turf.withOpacity(0.035)
      ..strokeWidth = 10;
    const espacamento = 22.0;
    final alcance = size.width + size.height;
    for (double x = -alcance; x < alcance; x += espacamento) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

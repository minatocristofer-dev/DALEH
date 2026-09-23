import 'package:flutter/material.dart';
import '../../../shared/widgets/crest_avatar.dart';
import '../../../theme/daleh_theme.dart';
import '../foto_perfil_layout.dart';
import '../models/meu_perfil.dart';

/// A "carta de jogador" do DALEH — layout definido pelo mockup "PERFIL —
/// PLAYER CARD" (QA de 2026-09-21): canto superior direito chanfrado, foto
/// do jogador encaixada nesse canto (a mesma foto composta com a camisa do
/// DALEH, gerada em EditarFotoScreen), nome em duas linhas, linhas de
/// informação com ícone, time em destaque com o escudo à direita, e
/// estatísticas em 4 colunas.
///
/// O mockup também tem data de entrada no time ("DESDE MAR 2024") e uma
/// fileira de badges/conquistas ("HISTÓRICO DALEH") — nenhum dos dois tem
/// campo correspondente no backend (TeamMember não guarda data de entrada,
/// e não existe nenhum sistema de conquistas). Por decisão do projeto de
/// nunca inventar dado, os dois ficam de fora daqui. O número da camisa
/// ("#10") já existe (definido pelo administrador do time — ver
/// TeamsService.atualizarMembro) e aparece quando o jogador tem um time
/// atual com número definido.
class PlayerCard extends StatelessWidget {
  final MeuPerfil perfil;
  const PlayerCard({super.key, required this.perfil});

  @override
  Widget build(BuildContext context) {
    final modalidadePrincipal = perfil.modalidadePrincipal;
    final time = perfil.timesAtuais.isEmpty ? null : perfil.timesAtuais.first;
    final outrosTimes = perfil.timesAtuais.length - 1;
    final (primeiraLinhaNome, ultimaLinhaNome) = _partesNome(perfil.fullName);

    final localizacao = [perfil.city, perfil.state].where((v) => v != null && v.isNotEmpty).join(' / ');
    final localizacaoTexto = [
      if (localizacao.isNotEmpty) localizacao.toUpperCase(),
      if (perfil.idade != null) '${perfil.idade} ANOS',
    ].join(' · ');

    final e = perfil.estatisticas;

    return ClipPath(
      clipper: const _ClipCantoChanfrado(raio: 24, chanfro: 36),
      child: CustomPaint(
        painter: const _MolduraCartao(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DALEH',
                                style: TextStyle(
                                  color: DalehColors.turf,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                primeiraLinhaNome.isNotEmpty ? primeiraLinhaNome : ultimaLinhaNome,
                                style: const TextStyle(
                                  color: DalehColors.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  height: 1.05,
                                ),
                              ),
                              if (primeiraLinhaNome.isNotEmpty)
                                Text(
                                  ultimaLinhaNome,
                                  style: const TextStyle(
                                    color: DalehColors.turf,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    height: 1.05,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: _fotoJogador()),
                      ],
                    ),
                  ),
                  if (time?.numeroCamisa != null)
                    Positioned(
                      top: -4,
                      right: 0,
                      child: Text(
                        '#${time!.numeroCamisa}',
                        style: const TextStyle(
                          color: DalehColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          height: 1,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (modalidadePrincipal != null)
                _linhaIcone(Icons.compare_arrows, modalidadePrincipal.posicaoPrincipal.toUpperCase()),
              if (perfil.dominantFoot != null) _linhaIcone(Icons.directions_run, 'PÉ ${perfil.dominantFoot!.toUpperCase()}'),
              if (localizacaoTexto.isNotEmpty) _linhaIcone(Icons.place_outlined, localizacaoTexto),
              _linhaTime(time, outrosTimes),
              const SizedBox(height: 6),
              const Divider(color: DalehColors.line, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  _estatistica('JOGOS', e.jogosDisputados),
                  _estatistica('GOLS', e.gols),
                  _estatistica('ASSISTÊNCIAS', e.assistencias),
                  _estatistica('MVPS', e.mvp),
                ],
              ),
              if (perfil.bio != null && perfil.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: DalehColors.line, height: 1),
                const SizedBox(height: 14),
                const Text(
                  'SOBRE',
                  style: TextStyle(color: DalehColors.text, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(perfil.bio!, style: const TextStyle(color: DalehColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoJogador() {
    return AspectRatio(
      aspectRatio: aspectoFotoPerfil,
      child: ClipPath(
        clipper: const _ClipCantoChanfrado(raio: 14, chanfro: 20),
        child: Container(
          color: DalehColors.surface2,
          child: perfil.avatarUrl != null && perfil.avatarUrl!.isNotEmpty
              ? Image.network(
                  perfil.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderFoto(),
                )
              : _placeholderFoto(),
        ),
      ),
    );
  }

  // Sem foto enviada ainda (a maioria dos perfis hoje) — mostra a mesma
  // estrutura do resultado final (silhueta + faixa da camisa na base) em
  // vez de um espaço vazio, só pra dar uma pista visual de onde a foto vai
  // aparecer. Não é dado inventado: é literalmente o template usado em
  // EditarFotoScreen.
  Widget _placeholderFoto() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(0, -0.22),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DalehColors.turf.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(Icons.person_outline, size: 22, color: DalehColors.muted),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: fracaoCamisaFotoPerfil,
            widthFactor: 1,
            child: Image.asset('assets/jerseys/jersey_solto.png', fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  Widget _linhaIcone(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icone, size: 16, color: DalehColors.turf),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: DalehColors.text, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaTime(TimeResumo? time, int outrosTimes) {
    if (time == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.groups_outlined, size: 16, color: DalehColors.muted),
            const SizedBox(width: 10),
            const Text('Sem time no momento', style: TextStyle(color: DalehColors.muted, fontSize: 13)),
          ],
        ),
      );
    }

    final nomeTime = outrosTimes > 0 ? '${time.name} +$outrosTimes' : time.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, size: 16, color: DalehColors.turf),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nomeTime,
              style: const TextStyle(color: DalehColors.text, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          CrestAvatar(url: time.crestUrl, nome: time.name, tamanho: 32),
        ],
      ),
    );
  }

  Widget _estatistica(String label, int valor) {
    return Expanded(
      child: Column(
        children: [
          Text('$valor', style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DalehColors.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// Último nome (ou única palavra) fica na 2ª linha, em lima — o resto do
// nome (quando houver) fica na 1ª linha, branco. Nome com uma palavra só
// devolve a primeira linha vazia, e o widget mostra só a linha lima.
(String, String) _partesNome(String nomeCompleto) {
  final partes = nomeCompleto.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return ('', '');
  if (partes.length == 1) return ('', partes.first.toUpperCase());
  final ultima = partes.removeLast();
  return (partes.join(' ').toUpperCase(), ultima.toUpperCase());
}

// Corpo do card: canto superior direito cortado na diagonal (chanfrado),
// os outros três arredondados — o mesmo desenho é usado tanto no card
// inteiro quanto no encaixe da foto (com raio/chanfro menores), pra um
// "aninhar" visualmente no outro.
Path _caminhoCantoChanfrado(Size size, {required double raio, required double chanfro}) {
  final w = size.width, h = size.height;
  return Path()
    ..moveTo(raio, 0)
    ..lineTo(w - chanfro, 0)
    ..lineTo(w, chanfro)
    ..lineTo(w, h - raio)
    ..quadraticBezierTo(w, h, w - raio, h)
    ..lineTo(raio, h)
    ..quadraticBezierTo(0, h, 0, h - raio)
    ..lineTo(0, raio)
    ..quadraticBezierTo(0, 0, raio, 0)
    ..close();
}

class _ClipCantoChanfrado extends CustomClipper<Path> {
  final double raio;
  final double chanfro;
  const _ClipCantoChanfrado({required this.raio, required this.chanfro});

  @override
  Path getClip(Size size) => _caminhoCantoChanfrado(size, raio: raio, chanfro: chanfro);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Preenche o corpo do card (gradiente campo-à-noite já usado no resto do
// app) e traça a borda lima por cima — desenhado à parte porque `ClipPath`
// sozinho não sabe desenhar borda numa forma customizada.
class _MolduraCartao extends CustomPainter {
  const _MolduraCartao();

  @override
  void paint(Canvas canvas, Size size) {
    final caminho = _caminhoCantoChanfrado(size, raio: 24, chanfro: 36);

    final preenchimento = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [DalehColors.surface2, DalehColors.bg],
      ).createShader(Offset.zero & size);
    canvas.drawPath(caminho, preenchimento);

    final borda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = DalehColors.turf.withValues(alpha: 0.6);
    canvas.drawPath(caminho, borda);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

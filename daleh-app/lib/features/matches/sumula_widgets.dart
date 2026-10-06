import 'package:flutter/material.dart';
import '../../shared/widgets/crest_avatar.dart';
import '../../theme/daleh_theme.dart';
import 'models/match.dart';
import 'models/match_event.dart';

/// Evento da súmula com o placar já calculado no momento dele (só gols).
class EventoComPlacar {
  final MatchEvent evento;
  final String? placarNoMomento;
  const EventoComPlacar({required this.evento, this.placarNoMomento});
}

const _diasSemana = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
const _meses = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];

String formatarDataHora(DateTime d) {
  final l = d.toLocal();
  final hora = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  return '${_diasSemana[l.weekday % 7]} ${l.day} ${_meses[l.month - 1]} • $hora';
}

String _rotuloStatusPartida(String status) {
  switch (status) {
    case 'scheduled':
      return 'AGENDADA';
    case 'in_progress':
      return 'EM ANDAMENTO';
    case 'finished':
      return 'ENCERRADA';
    case 'cancelled':
      return 'CANCELADA';
    default:
      return status.toUpperCase();
  }
}

/// Cabeçalho da súmula: escudo e nome de cada time, placar no centro, status
/// e data. Não mostra cronômetro — a partida não guarda minuto corrente.
class PlacarHeader extends StatelessWidget {
  final Match partida;
  const PlacarHeader({super.key, required this.partida});

  @override
  Widget build(BuildContext context) {
    final placar = partida.homeScore == null || partida.awayScore == null
        ? '×'
        : '${partida.homeScore} × ${partida.awayScore}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DalehRadius.lg),
        border: Border.all(color: DalehColors.turf),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14231C), Color(0xFF0A1512)],
        ),
      ),
      child: Column(
        children: [
          const Text('DALEH', style: TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Lado(nome: partida.homeTeamName ?? 'Time A', crestUrl: partida.homeTeamCrestUrl)),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(formatarDataHora(partida.scheduledAt),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: DalehColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(placar,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: DalehColors.turf, borderRadius: BorderRadius.circular(DalehRadius.pill)),
                      child: Text(_rotuloStatusPartida(partida.status),
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    if (partida.venueName != null) ...[
                      const SizedBox(height: 6),
                      Text(partida.venueName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: DalehColors.muted, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              Expanded(child: _Lado(nome: partida.awayTeamName ?? 'Time B', crestUrl: partida.awayTeamCrestUrl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Lado extends StatelessWidget {
  final String nome;
  final String? crestUrl;
  const _Lado({required this.nome, required this.crestUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CrestAvatar(url: crestUrl, nome: nome, tamanho: 52),
        const SizedBox(height: 6),
        Text(nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }
}

/// Eventos de um único time, em uma coluna. Cada time só aparece na sua coluna.
class ColunaEventosTime extends StatelessWidget {
  final String nome;
  final String? crestUrl;
  final List<EventoComPlacar> eventos;
  const ColunaEventosTime({super.key, required this.nome, required this.crestUrl, required this.eventos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CrestAvatar(url: crestUrl, nome: nome, tamanho: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(nome.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (eventos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum evento', textAlign: TextAlign.center, style: TextStyle(color: DalehColors.muted, fontSize: 12)),
          )
        else
          for (final item in eventos) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventoTile(item: item),
          ),
      ],
    );
  }
}

class EventoTile extends StatelessWidget {
  final EventoComPlacar item;
  const EventoTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final e = item.evento;
    final (cor, rotulo, icone) = _estilo(e.eventType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DalehColors.surface,
        borderRadius: BorderRadius.circular(DalehRadius.md),
        border: Border.all(color: DalehColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(e.minute != null ? "${e.minute}'" : '—',
                style: const TextStyle(color: DalehColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cor.withValues(alpha: 0.15), border: Border.all(color: cor)),
            child: icone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(rotulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    ),
                    if (item.placarNoMomento != null)
                      Text(item.placarNoMomento!,
                          style: const TextStyle(color: DalehColors.turf, fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(e.userFullName ?? 'Jogador',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, String, Widget) _estilo(String tipo) {
    switch (tipo) {
      case 'goal':
        return (DalehColors.turf, 'GOL', const Icon(Icons.sports_soccer, size: 16, color: DalehColors.turf));
      case 'assist':
        return (DalehColors.info, 'ASSISTÊNCIA', const Icon(Icons.handshake_outlined, size: 16, color: DalehColors.info));
      case 'yellow':
        return (
          DalehColors.amber,
          'CARTÃO AMARELO',
          Container(width: 9, height: 13, decoration: BoxDecoration(color: DalehColors.amber, borderRadius: BorderRadius.circular(2))),
        );
      case 'red':
        return (
          DalehColors.danger,
          'CARTÃO VERMELHO',
          Container(width: 9, height: 13, decoration: BoxDecoration(color: DalehColors.danger, borderRadius: BorderRadius.circular(2))),
        );
      default:
        return (DalehColors.muted, tipo.toUpperCase(), const Icon(Icons.adjust, size: 16, color: DalehColors.muted));
    }
  }
}

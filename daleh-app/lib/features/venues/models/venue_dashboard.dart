/// Painel do Locador (QA Round 2, Priority 4) — espelha `GET
/// /venues/:id/dashboard`. Dado real agregado pelo backend.
class TimeMaisFrequente {
  final String nome;
  final int reservas;
  TimeMaisFrequente({required this.nome, required this.reservas});

  factory TimeMaisFrequente.fromJson(Map<String, dynamic> json) =>
      TimeMaisFrequente(nome: json['nome'] as String, reservas: json['reservas'] as int);
}

class VenueDashboard {
  final int horariosDisponiveisHoje;
  final int reservasHoje;
  final int reservasMes;
  final double valorEmReservasHoje;
  final double valorEmReservasMes;
  final int indiceOcupacaoMes;
  final TimeMaisFrequente? timeMaisFrequente;

  VenueDashboard({
    required this.horariosDisponiveisHoje,
    required this.reservasHoje,
    required this.reservasMes,
    required this.valorEmReservasHoje,
    required this.valorEmReservasMes,
    required this.indiceOcupacaoMes,
    this.timeMaisFrequente,
  });

  factory VenueDashboard.fromJson(Map<String, dynamic> json) => VenueDashboard(
        horariosDisponiveisHoje: json['horariosDisponiveisHoje'] as int,
        reservasHoje: json['reservasHoje'] as int,
        reservasMes: json['reservasMes'] as int,
        valorEmReservasHoje: (json['valorEmReservasHoje'] as num).toDouble(),
        valorEmReservasMes: (json['valorEmReservasMes'] as num).toDouble(),
        indiceOcupacaoMes: json['indiceOcupacaoMes'] as int,
        timeMaisFrequente: json['timeMaisFrequente'] != null
            ? TimeMaisFrequente.fromJson(json['timeMaisFrequente'] as Map<String, dynamic>)
            : null,
      );
}

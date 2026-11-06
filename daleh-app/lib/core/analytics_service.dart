import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fino envoltório sobre o Firebase Analytics — nunca deixa uma falha de
/// analytics derrubar uma ação real do usuário (sem internet, Firebase
/// fora do ar, etc.). Eventos em português/snake_case, batendo com o que
/// já estava documentado em `docs/DALEH_PLAYSTORE_TEST_CHECKLIST.md`.
class AnalyticsService {
  Future<void> logEvento(String nome, {Map<String, Object>? parametros}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: nome, parameters: parametros);
    } catch (_) {
      // Analytics é observabilidade, não funcionalidade — uma falha aqui
      // nunca pode aparecer pro usuário nem interromper o fluxo real.
    }
  }
}

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

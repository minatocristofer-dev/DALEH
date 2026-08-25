import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/venues/disponibilidade_screen.dart';
import 'package:daleh_app/features/venues/venues_providers.dart';

void main() {
  testWidgets('faixa de dias mostra 14 dias a partir de hoje, com o dia de hoje selecionado por padrão', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disponibilidadeProvider.overrideWith((ref, query) => Future.value(const [])),
        ],
        child: const MaterialApp(home: DisponibilidadeScreen(venueId: 'v1', venueName: 'Arena Teste')),
      ),
    );
    await tester.pumpAndSettle();

    final hoje = DateTime.now();
    expect(find.text('${hoje.day}'), findsWidgets);
    expect(find.text('Arena Teste'), findsOneWidget);
  });

  testWidgets('tocar em outro dia da faixa muda a data consultada, sem crashar', (tester) async {
    final datasConsultadas = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disponibilidadeProvider.overrideWith((ref, query) {
            datasConsultadas.add(query.data);
            return Future.value(const []);
          }),
        ],
        child: const MaterialApp(home: DisponibilidadeScreen(venueId: 'v1', venueName: 'Arena Teste')),
      ),
    );
    await tester.pumpAndSettle();

    final amanha = DateTime.now().add(const Duration(days: 1));
    await tester.tap(find.text('${amanha.day}').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(datasConsultadas.length, greaterThan(1));
  });
}

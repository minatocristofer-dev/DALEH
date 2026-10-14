import 'package:daleh_app/features/perfil/editar_foto_screen.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('antes de escolher foto, mostra a moldura com a silhueta neutra e nunca um rosto inventado', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildDalehTheme(), home: const EditarFotoScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

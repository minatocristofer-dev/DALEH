import 'package:daleh_app/features/perfil/editar_foto_screen.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _tela({required String nome, String? posicao}) => ProviderScope(
      child: MaterialApp(
        theme: buildDalehTheme(),
        home: EditarFotoScreen(nome: nome, posicao: posicao),
      ),
    );

void main() {
  testWidgets('faixa do card mostra o nome em maiúsculas e a posição', (tester) async {
    await tester.pumpWidget(_tela(nome: 'Cristofer Teste', posicao: 'Ala'));
    await tester.pumpAndSettle();

    expect(find.text('CRISTOFER TESTE'), findsOneWidget);
    expect(find.text('ALA'), findsOneWidget);
  });

  testWidgets('sem posição cadastrada, a faixa mostra só o nome (sem inventar posição)', (tester) async {
    await tester.pumpWidget(_tela(nome: 'Cristofer Teste', posicao: null));
    await tester.pumpAndSettle();

    expect(find.text('CRISTOFER TESTE'), findsOneWidget);
    expect(find.text('ALA'), findsNothing);
  });

  testWidgets('antes de escolher foto, mostra o aviso e a silhueta neutra', (tester) async {
    await tester.pumpWidget(_tela(nome: 'Cristofer Teste', posicao: 'Ala'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_outline), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

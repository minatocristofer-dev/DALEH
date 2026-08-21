import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daleh_app/app.dart';

void main() {
  testWidgets('mostra a tela de login por padrão', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DalehApp()));
    await tester.pump();
    expect(find.text('Entrar'), findsWidgets);
  });
}

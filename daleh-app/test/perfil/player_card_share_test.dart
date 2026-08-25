import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/player_card_share.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('devolve false (sem lançar) quando a chave não está ligada a nenhum widget montado', () async {
    final chaveSolta = GlobalKey();

    final resultado = await compartilharPlayerCard(chaveSolta);

    expect(resultado, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';
import 'package:daleh_app/features/perfil/perfil_providers.dart';
import 'package:daleh_app/features/perfil/perfil_screen.dart';
import 'package:daleh_app/features/perfil/widgets/player_card.dart';

MeuPerfil _perfil() {
  return MeuPerfil.fromJson({
    'id': 'user-1',
    'fullName': 'Jogador Teste',
    'email': 'jogador@teste.com',
    'avatarUrl': null,
    'city': null,
    'state': null,
    'dominantFoot': null,
    'bio': null,
    'modalidades': [],
    'estatisticas': {
      'jogosDisputados': 0,
      'gols': 0,
      'assistencias': 0,
      'cartoesAmarelos': 0,
      'cartoesVermelhos': 0,
      'mvp': 0,
      'convocacoes': 0,
    },
    'timesAtuais': [],
    'timesAnteriores': [],
  });
}

void main() {
  testWidgets('carrega o perfil real e mostra o Player Card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [meuPerfilProvider.overrideWith((ref) => Future.value(_perfil()))],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerCard), findsOneWidget);
    expect(find.text('COMPARTILHAR PLAYER CARD'), findsOneWidget);
  });

  testWidgets('tocar em compartilhar aciona o botão sem crashar (fluxo de captura é coberto à parte)', (tester) async {
    // O card cresceu com a evolução visual da Fase 7 (glow do avatar, selo,
    // tagline em inglês) — aumenta a viewport do teste pra caber a tela
    // inteira sem precisar rolar até o botão.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [meuPerfilProvider.overrideWith((ref) => Future.value(_perfil()))],
        child: const MaterialApp(home: PerfilScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // `RenderRepaintBoundary.toImage()` não completa dentro do harness de
    // `flutter_test` (não há rasterizador real) — por isso só verificamos
    // aqui que o toque entra no estado de carregamento sem lançar exceção;
    // a resiliência de `compartilharPlayerCard` quando a captura/o
    // compartilhamento não estão disponíveis é testada isoladamente em
    // `player_card_share_test.dart`.
    //
    // O card cresceu com a evolução visual da Fase 7 (glow do avatar, selo,
    // tagline em inglês) — o botão pode ficar fora da viewport padrão do
    // teste (800x600) até rolar a ListView até ele.
    await tester.ensureVisible(find.text('COMPARTILHAR PLAYER CARD'));
    await tester.tap(find.text('COMPARTILHAR PLAYER CARD'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

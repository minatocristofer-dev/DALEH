import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';
import 'package:daleh_app/features/perfil/perfil_providers.dart';
import 'package:daleh_app/features/perfil/perfil_publico_screen.dart';
import 'package:daleh_app/features/perfil/widgets/player_card.dart';

MeuPerfil _perfil() {
  return MeuPerfil.fromJson({
    'id': 'user-2',
    'fullName': 'Outro Jogador',
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
  testWidgets('carrega e mostra o Player Card do outro jogador', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [perfilPublicoProvider('user-2').overrideWith((ref) => Future.value(_perfil()))],
        child: const MaterialApp(home: PerfilPublicoScreen(userId: 'user-2')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlayerCard), findsOneWidget);
    expect(find.text('OUTRO JOGADOR'), findsOneWidget);
    expect(find.text('COMPARTILHAR PLAYER CARD'), findsOneWidget);
    // Perfil de terceiro não tem botão de sair (isso só existe no próprio perfil).
    expect(find.text('Sair'), findsNothing);
  });

  testWidgets('jogador inexistente (404) mostra estado amigável, sem crash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          perfilPublicoProvider('user-inexistente').overrideWith(
            (ref) => Future.error(ApiException('Usuário não encontrado.', kind: ApiErrorKind.notFound)),
          ),
        ],
        child: const MaterialApp(home: PerfilPublicoScreen(userId: 'user-inexistente')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Usuário não encontrado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

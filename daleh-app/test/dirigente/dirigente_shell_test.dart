import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/dirigente/dirigente_shell.dart';
import 'package:daleh_app/features/teams/models/team.dart';
import 'package:daleh_app/features/teams/teams_providers.dart';

/// Fake genérico: qualquer caminho não mapeado em `respostas` devolve um
/// valor vazio (nunca lança, nunca sai pra rede de verdade) — suficiente
/// pra deixar as abas reaproveitadas (TeamDetailScreen/JogosRootScreen)
/// caírem num estado vazio/erro silencioso quando o teste não olha pra elas.
class _ApiClientFake implements ApiClient {
  @override
  Future<List<dynamic>> getLista(String path, {required String token}) async => [];
  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async => {};
  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async => null;
  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async =>
      {};
  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async => {};
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> enviarArquivo(
    String path, {
    required String token,
    required List<int> bytes,
    required String nomeArquivo,
    required String contentType,
  }) =>
      throw UnimplementedError();
}

Team _time({required String id, required String name, String? meuPapel, String ownerId = 'outro-dono'}) {
  return Team.fromJson({
    'id': id,
    'name': name,
    'ownerId': ownerId,
    'meuPapel': meuPapel,
    'totalMembros': 3,
  });
}

Future<void> _montar(WidgetTester tester, List<Team> times) async {
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(_ApiClientFake()),
      meuUserIdProvider.overrideWith((ref) => 'user-1'),
      meusTimesProvider.overrideWith((ref) => Future.value(times)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const MaterialApp(home: DirigenteShell())),
  );
  // `pump()` simples (não `pumpAndSettle`): as abas reaproveitadas mostram
  // `CircularProgressIndicator` (animação indeterminada) enquanto buscam
  // dados reais, o que trava um `pumpAndSettle`.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('sem time gerenciável: mostra aviso e CTA "CRIAR TIME" (não entra na gestão de nenhum time)',
      (tester) async {
    await _montar(tester, []);

    expect(find.text('Você ainda não gerencia um time.'), findsOneWidget);
    expect(find.text('CRIAR TIME'), findsOneWidget);
  });

  testWidgets('jogador comum (sem papel de gestão em nenhum time) também cai no aviso de "nenhum time"', (tester) async {
    await _montar(tester, [_time(id: 't1', name: 'Time do Zé', meuPapel: 'JOGADOR')]);

    expect(find.text('Você ainda não gerencia um time.'), findsOneWidget);
  });

  testWidgets('exatamente um time gerenciável: entra direto na gestão desse time (sem seletor)', (tester) async {
    await _montar(tester, [_time(id: 't1', name: 'Dirigentes FC', meuPapel: 'CAPITAO')]);

    expect(find.text('Você ainda não gerencia um time.'), findsNothing);
    expect(find.text('Dirigentes FC'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Jogos'), findsOneWidget);
  });

  testWidgets('dono do time (ownerId == meuUserId) conta como gerenciável mesmo sem meuPapel de gestão',
      (tester) async {
    await _montar(tester, [_time(id: 't1', name: 'Meu Time', ownerId: 'user-1', meuPapel: null)]);

    expect(find.text('Você ainda não gerencia um time.'), findsNothing);
    expect(find.text('Meu Time'), findsOneWidget);
  });

  testWidgets('mais de um time gerenciável: mostra seletor; tocar num time abre a gestão dele', (tester) async {
    await _montar(tester, [
      _time(id: 't1', name: 'Time Um', meuPapel: 'CAPITAO'),
      _time(id: 't2', name: 'Time Dois', ownerId: 'user-1'),
    ]);

    expect(find.text('Selecione o time'), findsOneWidget);
    expect(find.text('Time Um'), findsOneWidget);
    expect(find.text('Time Dois'), findsOneWidget);

    await tester.tap(find.text('Time Dois'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Selecione o time'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
  });
}

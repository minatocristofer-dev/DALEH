import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/core/auth_storage.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/auth/auth_controller.dart';
import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/matches_providers.dart';
import 'package:daleh_app/features/matches/matches_repository.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/teams/teams_providers.dart';

/// `comSessao` (usado pelas ações de registrar gol/eleger MVP/finalizar)
/// exige um token não-nulo em `authControllerProvider` — essa storage falsa
/// garante isso sem precisar de login de verdade.
class _AuthStorageComToken implements AuthStorage {
  @override
  Future<void> salvarToken(String token) async {}
  @override
  Future<String?> obterToken() async => 'token-de-teste';
  @override
  Future<void> limpar() async {}
}

class _ApiClientNuncaUsado implements ApiClient {
  @override
  Future<List<dynamic>> getLista(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) => throw UnimplementedError();
  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
}

class _FakeMatchesRepository extends MatchesRepository {
  _FakeMatchesRepository() : super(_ApiClientNuncaUsado());

  final chamadasGol = <Map<String, dynamic>>[];
  final chamadasMvp = <String>[];
  final chamadasStatus = <String>[];
  bool lancarErroAoRegistrarGol = false;

  @override
  Future<void> registrarGol(String matchId, String token, {required String scorerId, String? assistId, int? minute}) async {
    if (lancarErroAoRegistrarGol) {
      throw ApiException('Esse jogador não confirmou presença nessa partida.', kind: ApiErrorKind.badRequest);
    }
    chamadasGol.add({'matchId': matchId, 'scorerId': scorerId, 'assistId': assistId});
  }

  @override
  Future<void> elegerMvp(String matchId, String token, {required String userId}) async {
    chamadasMvp.add(userId);
  }

  @override
  Future<void> atualizarStatus(String matchId, String token, {required String status}) async {
    chamadasStatus.add(status);
  }
}

Match _partidaComTimes({
  required bool souGestorDaSumula,
  String status = 'scheduled',
  int? homeScore,
  int? awayScore,
  List<Map<String, dynamic>> eventos = const [],
}) {
  return Match.fromJson({
    'id': 'match-1',
    'createdById': 'user-criador',
    'modalidadeId': 'mod-1',
    'homeTeamId': 'time-a',
    'homeTeam': {'id': 'time-a', 'name': 'DALEH FC', 'crestUrl': null},
    'awayTeamId': 'time-b',
    'awayTeam': {'id': 'time-b', 'name': 'UNIÃO FC', 'crestUrl': null},
    'scheduledAt': '2026-09-10T20:00:00.000Z',
    'status': status,
    'visibility': 'public',
    'homeScore': homeScore,
    'awayScore': awayScore,
    'souGestorDaSumula': souGestorDaSumula,
    'attendance': [
      {
        'id': 'a1',
        'matchId': 'match-1',
        'userId': 'user-joao',
        'status': 'confirmed',
        'createdAt': '2026-08-21T00:00:00.000Z',
        'user': {'id': 'user-joao', 'fullName': 'João', 'avatarUrl': null},
      },
      {
        'id': 'a2',
        'matchId': 'match-1',
        'userId': 'user-pedro',
        'status': 'confirmed',
        'createdAt': '2026-08-21T00:00:00.000Z',
        'user': {'id': 'user-pedro', 'fullName': 'Pedro', 'avatarUrl': null},
      },
    ],
    'events': eventos,
  });
}

Future<_FakeMatchesRepository> _montar(
  WidgetTester tester, {
  required Match partida,
  String? meuUserId = 'user-criador',
}) async {
  final container = ProviderContainer(
    overrides: [
      partidaDetalheProvider('match-1').overrideWith((ref) => Future.value(partida)),
      matchesRepositoryProvider.overrideWith((ref) => _FakeMatchesRepository()),
      authStorageProvider.overrideWithValue(_AuthStorageComToken()),
      if (meuUserId != null) meuUserIdProvider.overrideWith((ref) => meuUserId),
    ],
  );
  addTearDown(container.dispose);
  final fake = container.read(matchesRepositoryProvider) as _FakeMatchesRepository;

  // `comSessao` (usado pelas ações de gol/MVP/finalizar) lê o token de
  // `authControllerProvider`. Como `meuUserIdProvider` é sobrescrito acima
  // (bypassando a leitura real de `authControllerProvider`), nada mais
  // constrói esse provider durante o build inicial — sem isso, a primeira
  // leitura só aconteceria no meio do toque no botão, antes do
  // `_carregarSessaoSalva()` assíncrono terminar, e a ação falharia com
  // "sessão expirou". Força a construção e deixa o storage falso resolver
  // antes de qualquer interação.
  container.read(authControllerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: JogoDetailScreen(matchId: 'match-1')),
    ),
  );
  // Um `Future.delayed` cru trava pra sempre contra o relógio falso do
  // `flutter_test` — `pump()` é o jeito correto de deixar o
  // `_carregarSessaoSalva()` assíncrono (dentro do AuthController) resolver.
  await tester.pump();
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  // `MatchesActions.registrarGol/elegerMvp/atualizarStatus` passam por
  // `comSessao`, que lê `authControllerProvider` — e o construtor de
  // `AuthController` escuta `supabase.auth.onAuthStateChange` desde o
  // início (login social), então precisa do Supabase inicializado mesmo
  // sem nenhum teste aqui tocar em login social (mesmo setup usado em
  // `test/widget_test.dart` e em `test/perfil/navegacao_perfil_publico_test.dart`).
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : null,
  );
  setUpAll(() async {
    await initSupabase();
  });

  testWidgets('mostra o placar calculado no cabeçalho', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: false, homeScore: 3, awayScore: 2));

    expect(find.text('3 × 2'), findsOneWidget);
  });

  testWidgets('mostra "×" quando ainda não há placar (partida sem times ainda, ou souGestorDaSumula false não afeta isso)', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: false));

    expect(find.text('×'), findsOneWidget);
  });

  testWidgets('exibe os eventos de gol e assistência na aba SÚMULA', (tester) async {
    await _montar(
      tester,
      partida: _partidaComTimes(
        souGestorDaSumula: false,
        eventos: [
          {
            'id': 'e1',
            'matchId': 'match-1',
            'userId': 'user-joao',
            'teamId': 'time-a',
            'eventType': 'goal',
            'createdAt': '2026-09-10T21:00:00.000Z',
            'user': {'id': 'user-joao', 'fullName': 'João'},
          },
          {
            'id': 'e2',
            'matchId': 'match-1',
            'userId': 'user-pedro',
            'teamId': 'time-a',
            'eventType': 'assist',
            'createdAt': '2026-09-10T21:00:00.000Z',
            'user': {'id': 'user-pedro', 'fullName': 'Pedro'},
          },
        ],
      ),
    );

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('João marcou um gol'), findsOneWidget);
    expect(find.text('Pedro deu uma assistência'), findsOneWidget);
  });

  testWidgets('capitão/gestor vê o botão "Registrar gol"', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar gol'), findsOneWidget);
  });

  testWidgets('jogador comum (não gestor) não vê o botão "Registrar gol"', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: false));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar gol'), findsNothing);
  });

  testWidgets('partida encerrada não mostra o botão de registrar gol, mesmo pro gestor', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true, status: 'finished'));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar gol'), findsNothing);
  });

  testWidgets('seleciona goleador e assistência e registra o gol', (tester) async {
    final fake = await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gol'));
    await tester.pumpAndSettle();

    // Goleador já vem pré-selecionado com o primeiro confirmado (João);
    // troca a assistência pra Pedro.
    await tester.tap(find.text('Sem assistência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pedro').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(fake.chamadasGol.single, {'matchId': 'match-1', 'scorerId': 'user-joao', 'assistId': 'user-pedro'});
  });

  testWidgets('registra gol sem assistência quando "Sem assistência" é mantido', (tester) async {
    final fake = await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(fake.chamadasGol.single['assistId'], isNull);
  });

  testWidgets('erro da API ao registrar gol é mostrado sem crashar', (tester) async {
    final fake = await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true));
    fake.lancarErroAoRegistrarGol = true;

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar gol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('Esse jogador não confirmou presença nessa partida.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('partida finalizada sem MVP: gestor vê "ELEJA O MVP DA PARTIDA"', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true, status: 'finished'));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('ELEJA O MVP DA PARTIDA'), findsOneWidget);
  });

  testWidgets('elege o MVP a partir da lista de confirmados', (tester) async {
    final fake = await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true, status: 'finished'));

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher MVP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eleger MVP'));
    await tester.pumpAndSettle();

    expect(fake.chamadasMvp.single, 'user-joao');
  });

  testWidgets('partida finalizada com MVP já eleito mostra o cartão do MVP, não o botão de eleição', (tester) async {
    await _montar(
      tester,
      partida: _partidaComTimes(
        souGestorDaSumula: true,
        status: 'finished',
        eventos: [
          {
            'id': 'mvp-1',
            'matchId': 'match-1',
            'userId': 'user-joao',
            'eventType': 'mvp',
            'createdAt': '2026-09-10T22:00:00.000Z',
            'user': {'id': 'user-joao', 'fullName': 'João'},
          },
        ],
      ),
    );

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('MVP da partida: João'), findsOneWidget);
    expect(find.text('ELEJA O MVP DA PARTIDA'), findsNothing);
  });

  testWidgets('criador vê "Finalizar partida" e confirma a finalização', (tester) async {
    final fake = await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true), meuUserId: 'user-criador');

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finalizar').last);
    await tester.pumpAndSettle();

    expect(fake.chamadasStatus.single, 'finished');
  });

  testWidgets('quem não é o criador não vê o botão de finalizar partida', (tester) async {
    await _montar(tester, partida: _partidaComTimes(souGestorDaSumula: true), meuUserId: 'user-capitao-b');

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar partida'), findsNothing);
  });

  testWidgets('eventos de gol mostram o placar evoluindo, calculado em ordem cronológica real (Fase visual)', (tester) async {
    await _montar(
      tester,
      partida: _partidaComTimes(
        souGestorDaSumula: false,
        eventos: [
          {
            'id': 'e1',
            'matchId': 'match-1',
            'userId': 'user-joao',
            'teamId': 'time-a',
            'eventType': 'goal',
            'createdAt': '2026-09-10T21:00:00.000Z',
            'user': {'id': 'user-joao', 'fullName': 'João'},
          },
          {
            'id': 'e2',
            'matchId': 'match-1',
            'userId': 'user-pedro',
            'teamId': 'time-b',
            'eventType': 'goal',
            'createdAt': '2026-09-10T21:10:00.000Z',
            'user': {'id': 'user-pedro', 'fullName': 'Pedro'},
          },
        ],
      ),
    );

    await tester.tap(find.text('SÚMULA'));
    await tester.pumpAndSettle();

    expect(find.text('1 × 0'), findsOneWidget);
    expect(find.text('1 × 1'), findsOneWidget);
  });

  testWidgets('aba PARTICIPANTES agrupa a escalação por time e por linha de posição (Fase visual)', (tester) async {
    final partida = Match.fromJson({
      'id': 'match-1',
      'createdById': 'user-criador',
      'modalidadeId': 'mod-1',
      'homeTeamId': 'time-a',
      'homeTeam': {'id': 'time-a', 'name': 'DALEH FC', 'crestUrl': null},
      'awayTeamId': 'time-b',
      'awayTeam': {'id': 'time-b', 'name': 'UNIÃO FC', 'crestUrl': null},
      'scheduledAt': '2026-09-10T20:00:00.000Z',
      'status': 'scheduled',
      'visibility': 'public',
      'souGestorDaSumula': false,
      'attendance': [
        {
          'id': 'a1',
          'matchId': 'match-1',
          'userId': 'user-joao',
          'status': 'confirmed',
          'createdAt': '2026-08-21T00:00:00.000Z',
          'teamId': 'time-a',
          'posicaoPrincipal': 'Goleiro',
          'user': {'id': 'user-joao', 'fullName': 'João', 'avatarUrl': null},
        },
        {
          'id': 'a2',
          'matchId': 'match-1',
          'userId': 'user-pedro',
          'status': 'confirmed',
          'createdAt': '2026-08-21T00:00:00.000Z',
          'teamId': 'time-b',
          'posicaoPrincipal': 'Atacante',
          'user': {'id': 'user-pedro', 'fullName': 'Pedro', 'avatarUrl': null},
        },
      ],
      'events': [],
    });

    // Os dois blocos de escalação (casa + fora) juntos passam da viewport
    // padrão do teste — aumenta o tamanho pra garantir que a ListView
    // construa os dois blocos inteiros, não só o que cabe na tela pequena.
    final tamanhoOriginal = tester.view.physicalSize;
    final pixelRatioOriginal = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = tamanhoOriginal;
      tester.view.devicePixelRatio = pixelRatioOriginal;
    });

    await _montar(tester, partida: partida);

    expect(find.text('DALEH FC'), findsWidgets);
    expect(find.text('UNIÃO FC'), findsWidgets);
    expect(find.text('GOLEIRO'), findsOneWidget);
    expect(find.text('ATAQUE'), findsOneWidget);
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Pedro'), findsOneWidget);
  });
}

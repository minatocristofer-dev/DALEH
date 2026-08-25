import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/supabase_config.dart';
import 'package:daleh_app/features/matches/jogo_detail_screen.dart';
import 'package:daleh_app/features/matches/matches_providers.dart';
import 'package:daleh_app/features/matches/models/match.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';
import 'package:daleh_app/features/perfil/perfil_providers.dart';
import 'package:daleh_app/features/perfil/perfil_publico_screen.dart';
import 'package:daleh_app/features/teams/models/call_up.dart';
import 'package:daleh_app/features/teams/models/team_member.dart';
import 'package:daleh_app/features/venues/minha_quadra_detail_screen.dart';
import 'package:daleh_app/features/venues/models/booking.dart';
import 'package:daleh_app/features/venues/models/venue.dart';
import 'package:daleh_app/features/venues/venues_providers.dart';
import 'package:daleh_app/shared/widgets/call_up_card.dart';
import 'package:daleh_app/shared/widgets/member_row.dart';

MeuPerfil _perfilPublico(String nome) {
  return MeuPerfil.fromJson({
    'id': 'qualquer-id',
    'fullName': nome,
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

Widget _appCom(Widget filho, {required String userIdEsperado}) {
  return ProviderScope(
    overrides: [perfilPublicoProvider(userIdEsperado).overrideWith((ref) => Future.value(_perfilPublico('Alvo Tocado')))],
    child: MaterialApp(home: Scaffold(body: filho)),
  );
}

void main() {
  // `JogoDetailScreen` lê `meuUserIdProvider`, que depende do
  // `authControllerProvider` — o construtor do `AuthController` escuta
  // `supabase.auth.onAuthStateChange` desde o início (login social), então
  // qualquer teste que monte essa tela precisa do Supabase inicializado,
  // mesmo sem tocar em login social (mesmo setup de `test/widget_test.dart`).
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalPrefs = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    canalPrefs,
    (call) async => call.method == 'getAll' ? <String, dynamic>{} : null,
  );
  setUpAll(() async {
    await initSupabase();
  });

  group('Navegação pro perfil público (Fase 7)', () {
    testWidgets('elenco do time (MemberRow): tocar no jogador abre o perfil público dele', (tester) async {
      final membro = TeamMember.fromJson({
        'id': 'm1',
        'teamId': 't1',
        'userId': 'user-alvo',
        'papel': 'JOGADOR',
        'status': 'active',
        'user': {'id': 'user-alvo', 'fullName': 'Jogador do Elenco', 'avatarUrl': null},
      });

      await tester.pumpWidget(_appCom(
        MemberRow(membro: membro, ehDono: false, possoGerenciar: false, souEuMesmo: false),
        userIdEsperado: 'user-alvo',
      ));

      await tester.tap(find.text('Jogador do Elenco'));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilPublicoScreen), findsOneWidget);
      // PlayerCard mostra o nome em caixa alta.
      expect(find.text('ALVO TOCADO'), findsOneWidget);
    });

    testWidgets('menu administrativo do MemberRow continua funcionando (não virou navegação)', (tester) async {
      var removeuFoiChamado = false;
      final membro = TeamMember.fromJson({
        'id': 'm1',
        'teamId': 't1',
        'userId': 'user-alvo',
        'papel': 'JOGADOR',
        'status': 'active',
        'user': {'id': 'user-alvo', 'fullName': 'Jogador do Elenco', 'avatarUrl': null},
      });

      await tester.pumpWidget(_appCom(
        MemberRow(
          membro: membro,
          ehDono: false,
          possoGerenciar: true,
          souEuMesmo: false,
          onAlterarPapel: (_) {},
          onRemover: () => removeuFoiChamado = true,
        ),
        userIdEsperado: 'user-alvo',
      ));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover do time'));
      await tester.pumpAndSettle();

      expect(removeuFoiChamado, isTrue);
      expect(find.byType(PerfilPublicoScreen), findsNothing);
    });

    testWidgets('convocações (CallUpCard): tocar no cabeçalho abre o perfil público do convocado', (tester) async {
      final callUp = CallUp.fromJson({
        'id': 'c1',
        'teamId': 't1',
        'matchId': null,
        'userId': 'user-convocado',
        'venueNameSnapshot': 'Arena Teste',
        'scheduledDate': '2026-09-10T00:00:00.000Z',
        'scheduledTime': '20:00',
        'status': 'PENDENTE',
        'respondedAt': null,
        'createdAt': '2026-08-21T00:00:00.000Z',
        'team': {'id': 't1', 'name': 'DALEH FC', 'crestUrl': null},
      });

      await tester.pumpWidget(_appCom(CallUpCard(callUp: callUp), userIdEsperado: 'user-convocado'));

      await tester.tap(find.text('DALEH FC'));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilPublicoScreen), findsOneWidget);
    });

    testWidgets('participantes de jogo: tocar no jogador confirmado abre o perfil público dele', (tester) async {
      final partida = Match.fromJson({
        'id': 'm1',
        'createdById': 'user-criador',
        'modalidadeId': 'mod-1',
        'modalidade': {'id': 'mod-1', 'key': 'SOCIETY', 'label': 'Society'},
        'scheduledAt': '2026-09-10T20:00:00.000Z',
        'status': 'scheduled',
        'visibility': 'public',
        'attendance': [
          {
            'id': 'a1',
            'matchId': 'm1',
            'userId': 'user-participante',
            'status': 'confirmed',
            'createdAt': '2026-08-21T00:00:00.000Z',
            'user': {'id': 'user-participante', 'fullName': 'Participante Confirmado', 'avatarUrl': null},
          },
        ],
      });

      await tester.pumpWidget(ProviderScope(
        overrides: [
          partidaDetalheProvider('m1').overrideWith((ref) => Future.value(partida)),
          perfilPublicoProvider('user-participante')
              .overrideWith((ref) => Future.value(_perfilPublico('Perfil do Participante'))),
        ],
        child: const MaterialApp(home: JogoDetailScreen(matchId: 'm1')),
      ));
      await tester.pumpAndSettle();

      // Abre a aba "PARTICIPANTES" (a tela já abre nela por padrão, mas
      // garantimos o estado navegando explicitamente pela TabBar).
      await tester.tap(find.text('PARTICIPANTES'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Participante Confirmado'));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilPublicoScreen), findsOneWidget);
    });

    testWidgets('reservas recebidas: tocar em quem reservou abre o perfil público dele', (tester) async {
      final quadra = Venue.fromJson({
        'id': 'v1',
        'ownerId': 'user-dono',
        'name': 'Arena Society',
        'covered': false,
        'hasParking': false,
        'hasBar': false,
        'hasLockerRoom': false,
        'rentsVests': false,
        'rentsBalls': false,
        'avgRating': 0,
      });
      final reserva = Booking.fromJson({
        'id': 'b1',
        'venueSlotId': 's1',
        'bookedById': 'user-locatario',
        'date': '2026-09-01T00:00:00.000Z',
        'status': 'pending',
        'venueSlot': {
          'id': 's1',
          'venueId': 'v1',
          'weekday': 1,
          'startTime': '19:00',
          'endTime': '20:00',
          'price': 100.0,
          'isRecurring': true,
          'venue': {'id': 'v1', 'name': 'Arena Society', 'address': null},
        },
        'bookedByUser': {'id': 'user-locatario', 'fullName': 'Quem Reservou', 'avatarUrl': null},
      });

      await tester.pumpWidget(ProviderScope(
        overrides: [
          quadraDetalheProvider('v1').overrideWith((ref) => Future.value(quadra)),
          reservasDaQuadraProvider('v1').overrideWith((ref) => Future.value([reserva])),
          perfilPublicoProvider('user-locatario')
              .overrideWith((ref) => Future.value(_perfilPublico('Perfil de Quem Reservou'))),
        ],
        child: const MaterialApp(home: MinhaQuadraDetailScreen(venueId: 'v1')),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RESERVAS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quem Reservou'));
      await tester.pumpAndSettle();

      expect(find.byType(PerfilPublicoScreen), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/api_client.dart';
import 'package:daleh_app/features/venues/venues_repository.dart';

class _Chamada {
  final String metodo;
  final String path;
  final Map<String, dynamic>? corpo;
  _Chamada(this.metodo, this.path, this.corpo);
}

class FakeApiClient implements ApiClient {
  final List<_Chamada> chamadas = [];
  final Map<String, dynamic> respostas;
  ApiException? erroParaLancar;
  FakeApiClient({this.respostas = const {}});

  @override
  Future<List<dynamic>> getLista(String path, {required String token}) async {
    chamadas.add(_Chamada('GET', path, null));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as List?) ?? [];
  }

  @override
  Future<Map<String, dynamic>> getMapa(String path, {required String token}) async {
    chamadas.add(_Chamada('GET', path, null));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<dynamic> postAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_Chamada('POST', path, corpo));
    if (erroParaLancar != null) throw erroParaLancar!;
    return respostas[path];
  }

  @override
  Future<Map<String, dynamic>> patchAutenticado(String path, {required String token, Map<String, dynamic>? corpo}) async {
    chamadas.add(_Chamada('PATCH', path, corpo));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<Map<String, dynamic>> deleteAutenticado(String path, {required String token}) async {
    chamadas.add(_Chamada('DELETE', path, null));
    if (erroParaLancar != null) throw erroParaLancar!;
    return (respostas[path] as Map<String, dynamic>?) ?? {};
  }

  @override
  Future<String> registrar(Map<String, dynamic> dto) => throw UnimplementedError();
  @override
  Future<String> login(String email, String senha) => throw UnimplementedError();
  @override
  Future<String> loginSocial(String accessTokenSupabase, {bool consentimento = true}) => throw UnimplementedError();
}

void main() {
  const token = 'token-de-teste';

  group('VenuesRepository', () {
    test('listarQuadras faz GET /venues sem filtro quando city não é informado', () async {
      final fake = FakeApiClient(respostas: {'/venues': []});
      final repo = VenuesRepository(fake);

      await repo.listarQuadras(token);

      expect(fake.chamadas.single.path, '/venues');
    });

    test('listarQuadras inclui a query de city quando informado', () async {
      final fake = FakeApiClient(respostas: {'/venues?city=Santa+Maria': []});
      final repo = VenuesRepository(fake);

      await repo.listarQuadras(token, city: 'Santa Maria');

      expect(fake.chamadas.single.path, '/venues?city=Santa+Maria');
    });

    test('obterQuadra faz GET /venues/:id', () async {
      final fake = FakeApiClient(respostas: {
        '/venues/v1': {
          'id': 'v1',
          'ownerId': 'user-1',
          'name': 'Arena',
          'covered': false,
          'hasParking': false,
          'hasBar': false,
          'hasLockerRoom': false,
          'rentsVests': false,
          'rentsBalls': false,
          'avgRating': 0,
        },
      });
      final repo = VenuesRepository(fake);

      final quadra = await repo.obterQuadra('v1', token);

      expect(quadra.name, 'Arena');
    });

    test('disponibilidade monta a query com a data', () async {
      final fake = FakeApiClient(respostas: {'/venues/v1/availability?date=2026-09-01': []});
      final repo = VenuesRepository(fake);

      await repo.disponibilidade('v1', '2026-09-01', token);

      expect(fake.chamadas.single.path, '/venues/v1/availability?date=2026-09-01');
    });

    test('criarQuadra envia só os campos preenchidos', () async {
      final fake = FakeApiClient(respostas: {
        '/venues': {
          'id': 'v1',
          'ownerId': 'user-1',
          'name': 'Nova Arena',
          'covered': false,
          'hasParking': false,
          'hasBar': false,
          'hasLockerRoom': false,
          'rentsVests': false,
          'rentsBalls': false,
          'avgRating': 0,
        },
      });
      final repo = VenuesRepository(fake);

      await repo.criarQuadra(token, name: 'Nova Arena', covered: true);

      expect(fake.chamadas.single.corpo, {'name': 'Nova Arena', 'covered': true});
    });

    test('editarQuadra propaga ApiException 403 quando o usuário não é dono', () async {
      final fake = FakeApiClient()..erroParaLancar = ApiException('Você não é o dono dessa quadra.', kind: ApiErrorKind.forbidden);
      final repo = VenuesRepository(fake);

      expect(
        () => repo.editarQuadra('v1', token, name: 'Novo nome'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.forbidden)),
      );
    });

    test('minhasQuadras faz GET /venues/mine', () async {
      final fake = FakeApiClient(respostas: {'/venues/mine': []});
      final repo = VenuesRepository(fake);

      await repo.minhasQuadras(token);

      expect(fake.chamadas.single.path, '/venues/mine');
    });

    test('criarSlot envia weekday/startTime/endTime/price', () async {
      final fake = FakeApiClient(respostas: {
        '/venues/v1/slots': {
          'id': 's1',
          'venueId': 'v1',
          'weekday': 0,
          'startTime': '18:00',
          'endTime': '19:00',
          'price': 100.0,
          'isRecurring': true,
        },
      });
      final repo = VenuesRepository(fake);

      await repo.criarSlot('v1', token, weekday: 0, startTime: '18:00', endTime: '19:00', price: 100);

      expect(fake.chamadas.single.corpo, {'weekday': 0, 'startTime': '18:00', 'endTime': '19:00', 'price': 100.0});
    });

    test('removerSlot propaga ApiException 404 quando o horário não existe', () async {
      final fake = FakeApiClient()..erroParaLancar = ApiException('Horário não encontrado.', kind: ApiErrorKind.notFound);
      final repo = VenuesRepository(fake);

      expect(
        () => repo.removerSlot('v1', 'slot-inexistente', token),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.notFound)),
      );
    });

    test('reservar envia só a data no corpo (o horário pertence ao slot)', () async {
      final fake = FakeApiClient(respostas: {
        '/venues/v1/slots/s1/bookings': {
          'id': 'b1',
          'venueSlotId': 's1',
          'bookedById': 'user-1',
          'date': '2026-09-01T00:00:00.000Z',
          'status': 'pending',
        },
      });
      final repo = VenuesRepository(fake);

      await repo.reservar('v1', 's1', token, data: '2026-09-01');

      expect(fake.chamadas.single.corpo, {'date': '2026-09-01'});
    });

    test('reservar propaga ApiException 409 quando o horário já foi reservado', () async {
      final fake = FakeApiClient()..erroParaLancar = ApiException('Esse horário já está reservado nessa data.', kind: ApiErrorKind.conflict);
      final repo = VenuesRepository(fake);

      expect(
        () => repo.reservar('v1', 's1', token, data: '2026-09-01'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.conflict)),
      );
    });

    test('minhasReservas faz GET /bookings/mine', () async {
      final fake = FakeApiClient(respostas: {'/bookings/mine': []});
      final repo = VenuesRepository(fake);

      await repo.minhasReservas(token);

      expect(fake.chamadas.single.path, '/bookings/mine');
    });

    test('cancelarReserva faz DELETE /bookings/:id', () async {
      final fake = FakeApiClient(respostas: {
        '/bookings/b1': {
          'id': 'b1',
          'venueSlotId': 's1',
          'bookedById': 'user-1',
          'date': '2026-09-01T00:00:00.000Z',
          'status': 'cancelled',
        },
      });
      final repo = VenuesRepository(fake);

      final reserva = await repo.cancelarReserva('b1', token);

      expect(reserva.cancelada, isTrue);
      expect(fake.chamadas.single.metodo, 'DELETE');
    });

    test('reservasDaQuadra faz GET /venues/:id/bookings', () async {
      final fake = FakeApiClient(respostas: {
        '/venues/v1/bookings': [
          {
            'id': 'b1',
            'venueSlotId': 's1',
            'bookedById': 'user-1',
            'date': '2026-09-01T00:00:00.000Z',
            'status': 'pending',
            'bookedByUser': {'id': 'user-1', 'fullName': 'Jogador Teste', 'avatarUrl': null},
          },
        ],
      });
      final repo = VenuesRepository(fake);

      final reservas = await repo.reservasDaQuadra('v1', token);

      expect(fake.chamadas.single.path, '/venues/v1/bookings');
      expect(reservas.single.bookedByUserFullName, 'Jogador Teste');
    });

    test('reservasDaQuadra propaga ApiException 403 quando o usuário não é dono da quadra', () async {
      final fake = FakeApiClient()..erroParaLancar = ApiException('Você não é o dono dessa quadra.', kind: ApiErrorKind.forbidden);
      final repo = VenuesRepository(fake);

      expect(
        () => repo.reservasDaQuadra('v1', token),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.forbidden)),
      );
    });

    test('atualizarStatusReserva envia o status certo em PATCH /bookings/:id/status', () async {
      final fake = FakeApiClient(respostas: {
        '/bookings/b1/status': {
          'id': 'b1',
          'venueSlotId': 's1',
          'bookedById': 'user-1',
          'date': '2026-09-01T00:00:00.000Z',
          'status': 'confirmed',
        },
      });
      final repo = VenuesRepository(fake);

      final reserva = await repo.atualizarStatusReserva('b1', token, status: 'confirmed');

      expect(reserva.confirmada, isTrue);
      expect(fake.chamadas.single.corpo, {'status': 'confirmed'});
      expect(fake.chamadas.single.metodo, 'PATCH');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';

void main() {
  group('MeuPerfil.fromJson', () {
    test('lê o formato completo de GET /auth/me', () {
      final perfil = MeuPerfil.fromJson({
        'id': 'user-1',
        'fullName': 'Cristofer Teste',
        'email': 'cristofer@teste.com',
        'avatarUrl': null,
        'city': 'Santa Maria',
        'state': 'RS',
        'dominantFoot': 'Direito',
        'bio': null,
        'idade': 33,
        'modalidades': [
          {'modalidade': 'FUTSAL', 'label': 'Futsal', 'posicaoPrincipal': 'Ala', 'posicaoSecundaria': null},
          {'modalidade': 'SOCIETY', 'label': 'Society', 'posicaoPrincipal': 'Meia', 'posicaoSecundaria': 'Atacante'},
        ],
        'estatisticas': {
          'jogosDisputados': 12,
          'gols': 5,
          'assistencias': 3,
          'cartoesAmarelos': 1,
          'cartoesVermelhos': 0,
          'mvp': 2,
          'convocacoes': 8,
        },
        'timesAtuais': [
          {'id': 'time-1', 'name': 'DALEH FC', 'crestUrl': null, 'papel': 'CAPITAO'},
        ],
        'timesAnteriores': [
          {'id': 'time-2', 'name': 'Ex-Time', 'crestUrl': null},
        ],
      });

      expect(perfil.fullName, 'Cristofer Teste');
      expect(perfil.email, 'cristofer@teste.com');
      expect(perfil.dominantFoot, 'Direito');
      expect(perfil.modalidadePrincipal?.posicaoPrincipal, 'Ala');
      expect(perfil.modalidades, hasLength(2));
      expect(perfil.estatisticas.jogosDisputados, 12);
      expect(perfil.estatisticas.gols, 5);
      expect(perfil.timesAtuais.single.name, 'DALEH FC');
      expect(perfil.timesAnteriores.single.name, 'Ex-Time');
      expect(perfil.idade, 33);
    });

    test('lida bem com jogador sem modalidade, sem time e sem nenhuma estatística real', () {
      final perfil = MeuPerfil.fromJson({
        'id': 'user-novo',
        'fullName': 'Novato',
        'email': 'novato@teste.com',
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

      expect(perfil.modalidadePrincipal, isNull);
      expect(perfil.modalidades, isEmpty);
      expect(perfil.timesAtuais, isEmpty);
      expect(perfil.estatisticas.gols, 0);
      expect(perfil.idade, isNull, reason: 'Fase 9 — a maioria dos perfis ainda não tem data de nascimento cadastrada');
    });

    test('lê o formato de GET /users/:id (perfil público, Fase 7) — sem a chave "email"', () {
      final perfil = MeuPerfil.fromJson({
        'id': 'user-2',
        'fullName': 'Outro Jogador',
        'avatarUrl': null,
        'city': 'Porto Alegre',
        'state': 'RS',
        'dominantFoot': 'Esquerdo',
        'bio': null,
        'modalidades': [],
        'estatisticas': {
          'jogosDisputados': 3,
          'gols': 1,
          'assistencias': 0,
          'cartoesAmarelos': 0,
          'cartoesVermelhos': 0,
          'mvp': 0,
          'convocacoes': 1,
        },
        'timesAtuais': [],
        'timesAnteriores': [],
      });

      expect(perfil.email, isNull);
      expect(perfil.fullName, 'Outro Jogador');
      expect(perfil.city, 'Porto Alegre');
    });
  });
}

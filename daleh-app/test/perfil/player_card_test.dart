import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/features/perfil/models/meu_perfil.dart';
import 'package:daleh_app/features/perfil/widgets/player_card.dart';
import 'package:daleh_app/theme/daleh_theme.dart';

// O card sempre é usado dentro de uma ListView na tela real (ver
// PerfilScreen/PerfilPublicoScreen) — envolve num scroll aqui também pra
// não estourar a viewport fixa do teste (o card cresceu com idade/pé
// dominante, Fase 9), do mesmo jeito que já era necessário em
// perfil_screen_test.dart.
Widget _comTema(Widget filho) =>
    MaterialApp(theme: buildDalehTheme(), home: Scaffold(body: SingleChildScrollView(child: filho)));

MeuPerfil _perfilCompleto() {
  return MeuPerfil.fromJson({
    'id': 'user-1',
    'fullName': 'Cristofer Teste',
    'email': 'cristofer@teste.com',
    'avatarUrl': null,
    'city': 'Santa Maria',
    'state': 'RS',
    'dominantFoot': 'Direito',
    'bio': 'Gosto de jogo intenso, tabelas rápidas e decidir no último passe.',
    'idade': 33,
    'modalidades': [
      {'modalidade': 'FUTSAL', 'label': 'Futsal', 'posicaoPrincipal': 'Ala', 'posicaoSecundaria': null},
      {'modalidade': 'SOCIETY', 'label': 'Society', 'posicaoPrincipal': 'Meia', 'posicaoSecundaria': null},
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
      {'id': 'time-1', 'name': 'DALEH FC', 'crestUrl': null, 'papel': 'CAPITAO', 'numeroCamisa': 10},
    ],
    'timesAnteriores': [],
  });
}

MeuPerfil _perfilVazio() {
  return MeuPerfil.fromJson({
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
}

void main() {
  testWidgets('mostra nome, posição, cidade, time e estatísticas reais quando tudo está preenchido', (tester) async {
    await tester.pumpWidget(_comTema(PlayerCard(perfil: _perfilCompleto())));

    // Nome quebrado em 2 linhas (mockup "PLAYER CARD", QA 2026-09-21): o
    // sobrenome (última palavra) fica destacado, o resto vai numa linha
    // separada.
    expect(find.text('CRISTOFER'), findsOneWidget);
    expect(find.text('TESTE'), findsOneWidget);
    expect(find.text('ALA'), findsOneWidget);
    expect(find.text('SANTA MARIA / RS · 33 ANOS'), findsOneWidget);
    expect(find.text('PÉ DIREITO'), findsOneWidget);
    expect(find.text('DALEH FC'), findsOneWidget);
    expect(find.text('#10'), findsOneWidget); // número da camisa, definido pelo administrador do time
    expect(find.text('12'), findsOneWidget); // jogos
    expect(find.text('5'), findsOneWidget); // gols
    expect(find.text('SOBRE'), findsOneWidget);
    expect(find.text('Gosto de jogo intenso, tabelas rápidas e decidir no último passe.'), findsOneWidget);
  });

  testWidgets('jogador novo (sem time, sem modalidade, tudo zerado) renderiza sem crashar e sem inventar dado', (tester) async {
    await tester.pumpWidget(_comTema(PlayerCard(perfil: _perfilVazio())));

    expect(find.text('NOVATO'), findsOneWidget);
    expect(find.text('Sem time no momento'), findsOneWidget);
    expect(find.text('0'), findsWidgets); // estatísticas zeradas, reais
    expect(find.textContaining('ANOS'), findsNothing, reason: 'sem birthDate, não inventa idade');
    expect(find.textContaining('PÉ '), findsNothing, reason: 'sem dominantFoot, não mostra a linha');
    expect(find.text('SOBRE'), findsNothing, reason: 'sem bio, não mostra a seção');
    expect(find.textContaining('#'), findsNothing, reason: 'sem time, não tem número de camisa pra mostrar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem foto enviada, mostra o template da camisa em branco (nunca um espaço vazio ou rosto inventado)', (tester) async {
    await tester.pumpWidget(_comTema(PlayerCard(perfil: _perfilCompleto())));

    final placeholder = tester.widgetList<Image>(find.byType(Image)).where(
      (img) => img.image is AssetImage && (img.image as AssetImage).assetName == 'assets/jerseys/jersey_solto.png',
    );
    expect(placeholder, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}

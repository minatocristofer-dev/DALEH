import 'package:daleh_app/features/perfil/editar_foto_screen.dart';
import 'package:daleh_app/theme/daleh_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

// Fake de plataforma do image_picker — simula exatamente o que foi achado em
// QA real num aparelho físico (permissão de câmera/galeria negada), nunca
// reproduzível no emulador (que concede permissão sem perguntar). Antes da
// correção, essa exceção derrubava o fluxo em silêncio; o teste prova que a
// tela mostra uma mensagem clara em vez de travar.
class _ImagePickerQueNega extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({required ImageSource source, ImagePickerOptions options = const ImagePickerOptions()}) {
    throw PlatformException(code: 'camera_access_denied', message: 'The user did not allow camera access.');
  }
}

void main() {
  testWidgets(
    'antes de escolher foto, mostra só o convite pra escolher — sem quadrado, boneco ou silhueta',
    (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildDalehTheme(), home: const EditarFotoScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Escolha uma foto de frente, com o rosto visível.'), findsOneWidget);
      expect(find.text('ESCOLHER FOTO'), findsOneWidget);
      // Nenhum crop/silhueta/placeholder antes da composição automática.
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permissão de câmera negada no aparelho: mostra mensagem clara, sem crashar e sem travar (bug de QA real)',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _ImagePickerQueNega();
      addTearDown(() => ImagePickerPlatform.instance = original);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildDalehTheme(), home: const EditarFotoScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ESCOLHER FOTO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Câmera'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível abrir a câmera. Verifique se o DALEH tem permissão de câmera nas configurações do aparelho.'),
        findsOneWidget,
      );
      // Continua na própria tela, com o botão de escolher foto ainda ativo
      // (não trava num spinner infinito, não navega pra lugar nenhum).
      expect(find.text('ESCOLHER FOTO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permissão de galeria negada no aparelho: mostra mensagem clara, sem crashar',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _ImagePickerQueNega();
      addTearDown(() => ImagePickerPlatform.instance = original);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildDalehTheme(), home: const EditarFotoScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ESCOLHER FOTO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Galeria'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível abrir a galeria. Verifique as permissões do DALEH nas configurações do aparelho.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

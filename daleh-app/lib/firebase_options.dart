import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Gerado a partir de `android/app/google-services.json` (projeto Firebase
/// `daleh-app-4511b`) — só Android configurado, igual ao resto do app (sem
/// iOS). Esses valores não são segredo de servidor: são o mesmo tipo de
/// identificador público que qualquer app Firebase expõe no APK (protegido
/// por regras do Firebase, não por sigilo).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase não está configurado pra web neste projeto.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não tem configuração pra ${defaultTargetPlatform.name} — só Android existe no DALEH.',
        );
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyD9RZZ_orH5_RDA_i6nbY_PSyw0w1Aozm4',
    appId: '1:145264719670:android:7bcc80f35a6a6f6bc3e597',
    messagingSenderId: '145264719670',
    projectId: 'daleh-app-4511b',
    storageBucket: 'daleh-app-4511b.firebasestorage.app',
  );
}

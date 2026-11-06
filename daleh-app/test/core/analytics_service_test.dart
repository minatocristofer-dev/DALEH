import 'package:flutter_test/flutter_test.dart';
import 'package:daleh_app/core/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logEvento nunca lança, mesmo sem Firebase inicializado (ambiente de teste)', () async {
    final service = AnalyticsService();

    // Sem `Firebase.initializeApp()` (não roda em `flutter test`),
    // `FirebaseAnalytics.instance` lançaria — o service precisa engolir isso
    // em silêncio, porque analytics nunca pode derrubar uma ação real do
    // usuário (ver comentário na classe).
    await expectLater(service.logEvento('evento_de_teste'), completes);
  });
}

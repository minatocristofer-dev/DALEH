import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/analytics_service.dart';
import 'core/supabase_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  try {
    // Analytics é opcional — se o Firebase falhar (sem rede, serviço fora
    // do ar), o app continua funcionando normalmente, só sem métricas.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await AnalyticsService().logEvento('app_opened');
  } catch (_) {}
  runApp(const ProviderScope(child: DalehApp()));
}

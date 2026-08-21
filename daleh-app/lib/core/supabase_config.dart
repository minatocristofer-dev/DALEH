import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://glgdiymnhmcvzhtmbqqb.supabase.co';
// Chave "anon" — pública por design, segura de expor no app.
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsZ2RpeW1uaG1jdnpodG1icXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2MTAzNTYsImV4cCI6MjEwMTE4NjM1Nn0.XAacR5Uk9dXya_Eh9Ol20HZ6bP3_uXnQo7WViT7zIDs';

Future<void> initSupabase() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

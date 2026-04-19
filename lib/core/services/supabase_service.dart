import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_app/core/constants/api_keys.dart';

/// Serviço para inicialização e acesso ao cliente Supabase.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  /// Inicializa o Supabase com as credenciais do projeto.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: ApiKeys.supabaseUrl,
      anonKey: ApiKeys.supabaseAnonKey,
    );
  }
}

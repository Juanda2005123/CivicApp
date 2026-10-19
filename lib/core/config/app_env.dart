import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment variables manager for VIGÍA.
/// Keeps variables empty by default until Supabase credentials are provided.
class AppEnv {
  static String get supabaseUrl =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
  static String get supabaseAnonKey =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

  /// Indicates whether Supabase credentials have been configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Initializes flutter_dotenv, tolerating empty or missing .env files
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Tolerates absence of environment variables during offline or early boot phases
    }
  }
}

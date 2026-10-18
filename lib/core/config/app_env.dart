import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gestor centralizado de variables de entorno para VIGÍA.
/// Mantiene las variables vacías por defecto hasta que el usuario suministre las credenciales de Supabase.
class AppEnv {
  static String get supabaseUrl =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
  static String get supabaseAnonKey =>
      dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

  /// Indica si las credenciales de Supabase ya fueron configuradas
  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Inicializa flutter_dotenv tolerando archivos .env vacíos o ausentes
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Tolera la ausencia o falta de variables en Fase 0 / Fase 1
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

/// Fuente de datos remota para autenticación cívica usando Supabase SDK.
class AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSource({required this.supabaseClient});

  /// Inicia sesión con email y contraseña
  Future<UsuarioModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('No se pudo autenticar el usuario en el servidor.');
    }

    return await _fetchUserProfile(user.id, user.email ?? email);
  }

  /// Registra una nueva cuenta cívica.
  /// Los metadatos son capturados por el trigger `handle_new_user` en PostgreSQL.
  Future<UsuarioModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
  }) async {
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nombre_completo': fullName.trim(),
        'ciudad_residencia_id': cityId,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Error al registrar usuario en Supabase.');
    }

    try {
      // Intenta obtener el perfil creado por el trigger
      return await _fetchUserProfile(user.id, user.email ?? email);
    } catch (_) {
      // Fallback si la replicación del trigger tarda unos milisegundos
      return UsuarioModel(
        id: user.id,
        email: user.email ?? email,
        nombreCompleto: fullName,
        ciudadResidenciaId: cityId,
        nivelReputacionId: 1,
        nivelReputacionNombre: 'Observador',
        puntosReputacion: 0,
        activo: true,
      );
    }
  }

  /// Cierra la sesión activa en Supabase
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// Obtiene los datos del ciudadano logueado
  Future<UsuarioModel?> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) return null;

    try {
      return await _fetchUserProfile(user.id, user.email ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Consulta el perfil en `public.usuario` haciendo JOIN con ciudad y reputación
  Future<UsuarioModel> _fetchUserProfile(String userId, String fallbackEmail) async {
    final data = await supabaseClient
        .from('usuario')
        .select('*, ciudad_cobertura(*), nivel_reputacion(*)')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw Exception('Perfil cívico no encontrado en la base de datos.');
    }

    return UsuarioModel.fromJson(data);
  }
}

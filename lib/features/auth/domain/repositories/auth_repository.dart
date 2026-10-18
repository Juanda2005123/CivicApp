import '../entities/usuario.dart';

/// Contrato abstracto del Repositorio de Autenticación Cívica (Inversión de Control).
/// Define las operaciones del negocio sin conocer la tecnología subyacente.
abstract class AuthRepository {
  /// Inicia sesión con correo electrónico y contraseña
  Future<Usuario> login({
    required String email,
    required String password,
  });

  /// Registra una nueva cuenta cívica vinculada a su ciudad de cobertura DANE
  Future<Usuario> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
  });

  /// Cierra la sesión activa del ciudadano
  Future<void> logout();

  /// Obtiene la sesión o datos del usuario actualmente autenticado, si existe
  Future<Usuario?> getCurrentUser();
}

import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Caso de Uso: Registrar ciudadano con catálogo cerrado DANE
class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<Usuario> call({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
  }) {
    return repository.register(
      email: email,
      password: password,
      nombreCompleto: nombreCompleto,
      ciudadId: ciudadId,
      ciudadNombre: ciudadNombre,
    );
  }
}

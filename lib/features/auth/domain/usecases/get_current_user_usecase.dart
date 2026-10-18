import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Caso de Uso: Recuperar el ciudadano en sesión activa
class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  Future<Usuario?> call() {
    return repository.getCurrentUser();
  }
}

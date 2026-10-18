import '../repositories/auth_repository.dart';

/// Caso de Uso: Cerrar sesión cívica
class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

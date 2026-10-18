import '../entities/usuario.dart';
import '../repositories/auth_repository.dart';

/// Caso de Uso: Iniciar sesión cívica
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<Usuario> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}

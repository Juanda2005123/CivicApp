import '../repositories/auth_repository.dart';

/// Use Case: Terminate active civic session.
class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

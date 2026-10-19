import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Retrieve active authenticated citizen
class GetCurrentUserUseCase {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  Future<User?> call() {
    return repository.getCurrentUser();
  }
}

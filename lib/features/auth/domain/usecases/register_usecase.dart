import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use Case: Register citizen with closed DANE catalog
class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) {
    return repository.register(
      email: email,
      password: password,
      fullName: fullName,
      cityId: cityId,
      cityName: cityName,
    );
  }
}

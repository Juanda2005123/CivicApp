import '../entities/user.dart';

/// Abstract contract for the Civic Authentication Repository (Inversion of Control).
/// Defines core business operations independent of external databases or frameworks.
abstract class AuthRepository {
  /// Signs in with email and password
  Future<User> login({
    required String email,
    required String password,
  });

  /// Registers a new citizen account linked to their official DANE coverage city
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  });

  /// Signs out the active citizen session
  Future<void> logout();

  /// Retrieves the currently authenticated citizen, if an active session exists
  Future<User?> getCurrentUser();
}

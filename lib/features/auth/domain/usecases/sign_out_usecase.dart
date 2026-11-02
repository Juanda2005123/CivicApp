import '../repositories/auth_repository.dart';

/// Use case: end the active session.
class SignOutUseCase {
  final AuthRepository _auth;

  SignOutUseCase(this._auth);

  Future<void> call() => _auth.signOut();
}

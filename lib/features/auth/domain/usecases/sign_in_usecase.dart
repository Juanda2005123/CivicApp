import '../entities/profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

/// Use case: sign a citizen in and load their profile.
///
/// Two steps: Auth validates the credentials and returns the account id, which
/// then identifies the profile row.
class SignInUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  SignInUseCase(this._auth, this._profiles);

  Future<Profile> call({required String email, required String password}) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Escribe tu correo y tu contraseña');
    }
    final user = await _auth.signIn(email: email.trim(), password: password);
    try {
      return await _profiles.getProfile(user.id);
    } on Exception {
      await _auth.signOut();
      rethrow;
    }
  }
}

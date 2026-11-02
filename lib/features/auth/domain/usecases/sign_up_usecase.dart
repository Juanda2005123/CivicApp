import '../entities/profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../validators/password_policy.dart';
import '../validators/registration_rules.dart';

/// Use case: register a citizen.
///
/// Registering is two operations against two services, and this class fixes
/// their order: first the Auth account, then the profile row keyed by the
/// account id returned by Auth.
class SignUpUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  SignUpUseCase(this._auth, this._profiles);

  Future<Profile> call({
    required String fullName,
    required String email,
    required String password,
    required String cityName,
  }) async {
    final problem = RegistrationRules.validateFullName(fullName) ??
        RegistrationRules.validateEmail(email) ??
        PasswordPolicy.validate(password) ??
        (cityName.trim().isEmpty ? 'Elige tu ciudad' : null);
    if (problem != null) throw Exception(problem);

    final user = await _auth.signUp(email: email.trim(), password: password);
    final profile = Profile(
      id: user.id,
      email: user.email,
      fullName: fullName.trim(),
      cityName: cityName.trim(),
    );

    try {
      await _profiles.createProfile(profile);
    } on Exception {
      // The account already exists but has no profile: leave no half-open
      // session behind and tell the citizen what happened.
      await _auth.signOut();
      throw Exception(
        'Tu cuenta se creó pero no pudimos guardar tu perfil. '
        'Ingresa para intentarlo de nuevo.',
      );
    }
    return profile;
  }
}

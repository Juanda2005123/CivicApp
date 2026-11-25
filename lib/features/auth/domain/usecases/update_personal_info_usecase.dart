import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../validators/registration_rules.dart';

/// Result of updating personal info (HU-04): indicates whether the citizen
/// must confirm a new email address from their inbox.
class UpdatePersonalInfoResult {
  final bool emailVerificationPending;

  const UpdatePersonalInfoResult({required this.emailVerificationPending});
}

/// Validates and saves personal information: full name, reference city, and
/// optional email change (HU-04).
class UpdatePersonalInfoUseCase {
  final ProfileRepository _profiles;
  final AuthRepository _auth;

  UpdatePersonalInfoUseCase(this._profiles, this._auth);

  Future<UpdatePersonalInfoResult> call({
    required String userId,
    required String currentEmail,
    required String fullName,
    required String cityName,
    required String email,
  }) async {
    final nameError = RegistrationRules.validateFullName(fullName);
    if (nameError != null) throw Exception(nameError);

    final trimmedCity = cityName.trim();
    if (trimmedCity.isEmpty) throw Exception('Elige tu ciudad');

    final emailError = RegistrationRules.validateEmail(email);
    if (emailError != null) throw Exception(emailError);

    final trimmedEmail = email.trim();
    await _profiles.updateProfileInfo(
      userId: userId,
      fullName: fullName.trim(),
      cityName: trimmedCity,
    );

    if (trimmedEmail.toLowerCase() != currentEmail.trim().toLowerCase()) {
      await _auth.updateEmail(trimmedEmail);
      return const UpdatePersonalInfoResult(emailVerificationPending: true);
    }

    return const UpdatePersonalInfoResult(emailVerificationPending: false);
  }
}

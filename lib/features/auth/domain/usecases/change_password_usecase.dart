import '../repositories/auth_repository.dart';
import '../validators/password_policy.dart';

/// Validates current and new password complexity and delegates the change (HU-04).
class ChangePasswordUseCase {
  final AuthRepository _auth;

  ChangePasswordUseCase(this._auth);

  Future<void> call({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty) {
      throw Exception('Escribe tu contraseña actual');
    }
    final policyError = PasswordPolicy.validate(newPassword);
    if (policyError != null) throw Exception(policyError);

    await _auth.updatePassword(
      currentEmail: currentEmail,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

import '../entities/auth_user.dart';

/// Contract for the authentication service (credentials only).
abstract class AuthRepository {
  /// Creates the account. The returned user has an active session.
  Future<AuthUser> signUp({required String email, required String password});

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();

  /// The account of the persisted session, or `null` when nobody is signed in.
  AuthUser? currentUser();

  /// Requests an email change; Supabase sends a confirmation link to [newEmail].
  Future<void> updateEmail(String newEmail);

  /// Verifies [currentPassword] and updates the password to [newPassword].
  Future<void> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  });
}

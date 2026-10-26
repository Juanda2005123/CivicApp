import '../entities/profile.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';

/// Use case: profile of the persisted session, or `null` if nobody is signed in.
class GetCurrentProfileUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  GetCurrentProfileUseCase(this._auth, this._profiles);

  Future<Profile?> call() async {
    final user = _auth.currentUser();
    if (user == null) return null;
    return _profiles.getProfile(user.id);
  }
}

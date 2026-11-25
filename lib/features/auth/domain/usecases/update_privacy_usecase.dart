import '../repositories/profile_repository.dart';

/// Updates whether the citizen's real name is publicly shown on contributions (HU-01).
class UpdatePrivacyUseCase {
  final ProfileRepository _profiles;

  UpdatePrivacyUseCase(this._profiles);

  Future<void> call({required String userId, required bool showRealName}) {
    return _profiles.updatePrivacy(userId: userId, showRealName: showRealName);
  }
}

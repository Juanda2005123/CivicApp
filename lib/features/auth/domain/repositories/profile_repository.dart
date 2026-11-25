import 'dart:typed_data';

import '../entities/profile.dart';

/// Contract for the citizen profile stored next to the Auth account.
abstract class ProfileRepository {
  Future<void> createProfile(Profile profile);

  /// Throws when the account has no profile.
  Future<Profile> getProfile(String id);

  /// Remembers the city the citizen is exploring (`last_city`, HU-21).
  Future<void> updateLastCity(String id, String cityName);

  /// Updates whether the citizen's real name is shown on reports and comments (HU-01).
  Future<void> updatePrivacy({required String userId, required bool showRealName});

  /// Updates personal info (`full_name`, `reference_city`) for HU-04.
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  });

  /// Uploads a new civic avatar and saves its public URL on `user_profile` (HU-05).
  Future<String> updateAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}

import '../../../auth/domain/entities/profile.dart';

/// `guest`: browsing without an account (HU-22); `signedOut`: the citizen
/// just closed the session and goes back to the login.
enum ProfileStatus { initial, loading, success, failure, guest, signedOut }

class ProfileState {
  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

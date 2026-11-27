abstract class ProfileEvent {}

/// The summary screen opened: load the profile of the active session and its impact.
class ProfileStarted extends ProfileEvent {}

/// The citizen came back to "Mi perfil" or pulled to refresh: read the profile
/// and the impact again without blanking what is on screen (HU-23 criterion 3).
class ProfileRefreshed extends ProfileEvent {}

/// The citizen asked to log out.
class SignOutRequested extends ProfileEvent {}

/// The citizen tapped their avatar to pick and upload a new one (HU-05).
class ProfileAvatarChangeRequested extends ProfileEvent {
  final bool fromCamera;

  ProfileAvatarChangeRequested({required this.fromCamera});
}

abstract class ProfileEvent {}

/// The summary screen opened: load the profile of the active session.
class ProfileStarted extends ProfileEvent {}

/// The citizen asked to log out.
class SignOutRequested extends ProfileEvent {}
